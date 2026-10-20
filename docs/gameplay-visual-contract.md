# Official final gameplay visual — October 11, 2026

## October 17, 2026 — No Rune Slot inspection

Board slots must never open information windows through tap, hold or any inspect action. This includes empty slots, installed runes/connectors and Begin/End. Preserve normal selection, placement, rotation and page dragging. Hand-card, toolbar and pile details remain available; earlier requirements for board-piece inspection are superseded.

## October 17, 2026 — Centered hand and mobile controls

Remove the suggestion/action-message row above the hand. Keep the 146 px card lane centered between the toolbar and forecast with equal 10 px gaps, including during sequential card fades and empty-hand states. Production uses tap, hold, Info/Close and drag. Remove right-click inspection and desktop keyboard/controller/wheel actions, including in Guide and Menu. These owner changes supersede earlier action-log and desktop-control requirements below.

## October 17, 2026 — Stable hand height and darker Pass Turn text

The production hand reserves the compact card's full 146 px height even when empty, keeping the forecast, Cast and navigation in place through card removal and drawing. Draw/Discard retain their centered 139 px controls and the hand remains horizontally scrollable. Pass Turn uses the same parchment background and dark ink as the Turn-number label, retaining its existing shape, hit target and confirmation action. Its text stays dark in normal, hover, pressed, focused and disabled states; standard pressed/availability feedback remains.

Each drawn or generated card fades in over 0.40 s before the next arrives. Existing cards stay opaque; the hand reveals incoming cards horizontally while retaining its height and vertical page position. Reduced motion uses brief 0.06 s fades. [Animation contract](combat-animation.md), [verification](rc-017-verification.md#october-17-owner-follow-up--sequential-card-arrival-fades).

## Current consolidated baseline — October 16, 2026

RC-016 is complete per owner confirmation. Preserve the original reference together with these later owner changes: wordmark left/floor right; no BOSS caption or top Pause; compact card cost gems with no category row; display-only Damage/Shield/Cost with no Incoming; no Cast caption, hover popups or floating unavailable badges. Confirmed Pass and supported card/piece/connector/pile inspection remain. Rune symbols (Spark, Shield and Free Spark) and Split/Join central glyphs stay upright while their logical ports and visible wires rotate.

The current player status strip uses the generated [painted frame](../assets/ui/combat/reference/status-frame.png), 54 px row and 36 px content well; earlier patch/polygon border and 30 px well descriptions below are dated history. The current neutral uses the approved-atlas silhouette. RC-017 must reconcile it with retained attack/hit poses and clean hidden scenery. See the [latest integration record](rc-016-integration.md) and [retained runtime capture](../output/qa/rc-016/stats-generated-frame/normal-desktop.png). No complete pixel identity, rights clearance or physical-device result is implied.

## October 15, 2026 — Display-only forecast and frame cleanup

The owner's latest instruction makes the Damage/Shield/Cost bar above Cast display-only. It must not open a window on tap or hold and must not receive keyboard focus. Card Info, card/piece/connector and pile inspection, and confirmed Pass remain available. This takes precedence over earlier forecast-details guidance without changing circuit rules, live forecast values or Cast availability.

Player Health/Energy/Turn must sit inside a continuous closed frame with inset dividers. The repaired strip retains its 54 px height and 30 px padded well. The board and surrounding backdrop must exclude neighboring toolbar and old-board-corner pixels so no stray gold line appears at the lower-right edge. These are sampling corrections; original source artwork and gameplay geometry remain unchanged.

[Current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](rc-016-integration.md#october-15-2026--display-only-forecast-and-frame-cleanup) and [verification](verification.md#october-15-2026--display-only-forecast-and-frame-cleanup) describe the current revision. Dated entries below remain historical where superseded.

## October 15, 2026 — Header order and connector rotation

The latest owner instruction places Rune Cast at the left and the live floor name at the right of the full-width header. Split keeps its approved sideways-fork icon and Join its upright trident at every rotation. Rotate changes their logical ports and visible connection lines; the central icons keep their approved orientation and do not define the active ports.

The upper-left card frame must remain continuous around the smaller cost badge. Its clean upper-right corner is mirrored horizontally into that position, replacing the incorrectly oriented lower-corner sample without changing card dimensions or badge padding.

The original reference pile artwork and live counts remain. Card cost symbols stay 25×29 with 20 px live numerals. Original source artwork is retained. [Current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](rc-016-integration.md#october-15-2026--header-order-and-connector-rotation) and [verification](verification.md#october-15-2026--header-order-and-connector-rotation) supersede the earlier header order below.

## October 15, 2026 — Header and reference pile correction

The latest header correction keeps the floor name at the left and restores the approved Rune Cast wordmark at the right, inside a 52 px header that spans the full portrait viewport. Pause remains removed. Draw and Discard use their own original reference stack bodies and emblems, uniformly scaled; counts and captions remain live. This supersedes the earlier mirrored generic-pile approach and wordmark removal.

Stats background must stop at its painted silhouette, preserving the existing 54 px frame and 30 px well. The stray line beside Pass must be excluded from the toolbar sample: it was the original WIRING parchment edge within the old left cap. Compact cards use a 25×29 energy-cost symbol with a 20 px numeral. No source PNG was added, modified or deleted. [Current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](rc-016-integration.md#october-15-2026--header-and-reference-pile-correction) and [verification](verification.md#october-15-2026--header-and-reference-pile-correction) record this revision. Earlier dated requirements below remain authoritative only where consistent with these corrections.

## October 15, 2026 — Mobile presentation corrections

The latest explicit owner instructions override the corresponding parts of the approved painting: the floor name occupies the left of the header, with no Combat wordmark or Pause button; the BOSS caption above Shadeling is removed. The encounter's boss role and gameplay remain unchanged. Draw and Discard symbols center on their front cards, and Discard's stack artwork is mirrored horizontally without reversing text or symbols.

Every live element must stay inside the painted content well with visible padding. Stats use a 30 px high well, 24/11/24/13 margins and 26 px values (21 px Turn); bottom navigation keeps icons in y13–43 and captions in y45–69 of its 82 px frame. Pass and Cast exclude neighboring atlas pixels outside their silhouettes. Production hover tooltips and extra invalid/unavailable x/circle badges are hidden; focus, selection, availability guards and tap/hold/Info/forecast/Pass details remain. Deferred layout work must ignore controls that have already been freed. No new or modified source PNG is part of this correction.

[Current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](rc-016-integration.md#october-15-2026--mobile-presentation-corrections) and [verification](verification.md#october-15-2026--mobile-presentation-corrections) record these changes. Earlier dated requirements below are historical wherever they conflict with this section.

**October 15 artwork follow-up:** The owner now explicitly asks to fix all remaining artwork differences against the exact approved reference. This supersedes reconstruction-only production restrictions for clean, separable decoration: original empty sockets, border segments, unmarked materials and the static product wordmark may be sampled from the approved image. The complete screenshot, text-bearing panels, baked combat values and baked circuit paths remain prohibited. Generated transparent character/icons and an empty arena reconstruct obscured regions. [Current implementation and residual differences](rc-016-integration.md#october-15-2026--approved-reference-artwork-adoption), [source records](../source-assets/ui/combat/reference/README.md) and [verification](verification.md#october-15-2026--approved-reference-artwork-adoption) distinguish exact sampled pixels from the still nonidentical complete render. The later owner overrides below remain authoritative.

**Earlier October 15 owner overrides, retained:** Gameplay cards omit the Rune/Technique category row; the forecast above Cast omits Incoming and centers Damage, Shield and Cost. The latest override makes that bar display-only; incoming attack remains visible in Pass confirmation, and the mobile correction suppresses the former Cast hover tooltip. The Cast-ends-turn caption is removed, and circuit controls retain visible padding inside their frame. These explicit changes supersede the corresponding painted-reference rows without changing gameplay rules. See the [earlier full-screen comparison (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [integration](rc-016-integration.md#october-15-2026--full-screen-reference-alignment).

**October 13 evaluator/control clarification:** The owner approved the RC-016A contract and requested **Pass turn** in the WIRING-label position beside the four connector tools. Production now uses undirected logical ports, the accepted branch/rejoin and feedback rules, Remove/Rotate controls, safe inspection access, detailed cards, live piles and the forecast above Cast. The retained approved image is unchanged; the Pass turn placement is a subsequent owner instruction. See [decisions](decisions.md#october-13-2026--rc-016a-undirected-graph-and-controls-accepted), [gameplay rules](gameplay-rules.md) and [touch interactions](touch-interactions.md). [RC-016](rc-016-integration.md) binds the delivered painted crypt, character and shared UI to normal playable Combat; current runtime results and completion status are recorded separately in [verification](verification.md).

**October 12 Menu/progression clarification:** The menu's former Shop label is now **Store**, a separate destination for purchasing in-game items such as runes, perks and relics. It is not a shortcut restricted to shop rooms. Entering a shop room opens that room as the main screen. The owner also intends permanent rune acquisition from conquering a map or defeating a hard boss; detailed progression and purchase rules remain planned. This updates Menu semantics without altering the retained approved images or the Combat requirements below. See the current [design specification](v1-design-spec.md) and [current corrected menu specimen](../output/art/rc-013/menu-button-revert/menu-open-360x640.png).

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
| Pass turn | The October 13 owner clarification replaces the WIRING label with a visible **Pass turn** action beside the connector tools. It opens a confirmation showing incoming attack and cleanup, including from an incomplete circuit or empty hand; it is a turn action, not a third editing action |
| Hand and piles | Detailed cards show compact energy cost, name, symbol and short effect description, without a Rune/Technique category row. Draw pile left and Discard right preserve distinct artwork and live counts |
| Information above Cast | Display-only Damage/Shield/Cost above Cast; no Incoming field, tap/hold action, focus or modal. Keep the small action-log line above the hand |
| Primary action and navigation | Large turquoise pointed Cast, blue energy crystal and live cost; no Cast ends turn caption. Keep Menu, Map, Guide and Sound navigation; top Pause remains removed. Wordmark left, live floor name right |

## Rules change and implementation boundary

The owner's directionless-circuit request changes gameplay as well as rendering. Connected compatible ports work in either traversal direction; a route is not rejected solely because an old input/output label is reversed. Begin remains the source and End the sink. Rotation-zero logical ports are Begin E, End N, Straight/rune W/E, Corner W/S, Split W/E/S and Join N/E/S. Split branches one route into two; Join merges two into one, with roles inferred from complete Begin-to-End routes. Decorative symbol tips do not define ports.

The October 13 decision permits ordinary branch/rejoin loops, rejects open powered ports, dead branches and conflicting feedback/cross-links, and prevents repeated execution of a physical rune. Split preserves amplification: Spark6 before two branches contributes12; a shared Spark6 after Join contributes6 once. Each physical rune or connector pays its casting cost once. End emits one aggregate damage event. The production evaluator now implements that contract; historical no-options/experiment evaluation remains directed.

Production provides separate focusable Info buttons on hand cards, 450 ms hold-to-inspect, and I/right-click inspection for pieces/tools. The forecast is display-only and has no inspection action. Escape or tapping the selected card/tool clears selection. Pass turn opens the accepted confirmation in the wiring row. Detailed cards reuse RC-013 components and RC-012 icons; pile counts, action log and forecast read live snapshots. The forecast stays visible as a page component above Cast and scrolls with that page. RC-016 preserves these bindings in the playable painted composition; the proportional actor crop, readable native layout and intended page/hand/detail scrolling are documented in its integration guide. Technical desktop evidence does not establish owner aesthetic approval, painted-art rights or physical-device acceptance.

Dated documentation of the earlier directed controls remains historical evidence. Direction arrows, Flip/Undo/Inspect/Cancel/Details-Pass buttons, compact-only hand and no-forecast requirements must not be reintroduced into production. Existing affordability, busy-state, modal and terminal-state guards remain in force.

The approved raster contains a yellow BOSS label above Shadeling's name/health. The latest October 15 direction removes that caption from normal Combat, while the October 12 designation of Shadeling as a boss for one map encounter remains. Infinity stock, the particular board layout, HP, Turn2, Draw8/Discard5 and external12damage/1cost are illustrative values. The user did not separately request infinite connector supply, a guaranteed opening arrangement, or new balance values. The boss role does not establish final-guardian status, extra phases or permanent rewards. Removing board values does not remove their underlying gameplay data or the external forecast. Keep live state separate; do not bake this screen into the game as a replacement for controls.

## Scope and acceptance

The official final-image request is fulfilled by the exact supplied complete artwork. The earlier pilot's crypt/supporting-UI exclusions and permission to use placeholders are superseded for subsequent complete-preview production. Any rebuilt preview must match this entire image's visual construction; producing only a closer character/button does not meet that requirement.

This approval applies to this supplied image. It does not retroactively approve reconstructed assets, complete RC-012–RC-017, verify runtime behavior or prove device readiness. The [r006 editable pilot](../source-assets/pilot/revisions/r006/delivery.md) applies the latest board cleanup and corrected symbols while reusing r004 painted sources. Earlier revisions remain historical. Its assistant visual/source review is separate from owner approval of the supplied image. The original no-Git restriction remains in force.
