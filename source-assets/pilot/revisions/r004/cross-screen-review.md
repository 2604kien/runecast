# RC-011 r004 — independent visual review

October 11, 2026. Reviewed the actual approved [final Combat](../../../../output/imagegen/approved/combat-final.png), [Home](../../../../output/imagegen/approved/home.png), [Map](../../../../output/imagegen/approved/map.png) and [Menu](../../../../output/imagegen/approved/menu.png) images. The [accepted gameplay visual contract](../../../../docs/gameplay-visual-contract.md) supersedes the older directed-circuit and editing-control requirements. This record is an assistant's technical/art-direction review, not owner approval or runtime/device acceptance.

## Direct comparisons

| Reference | Observed r004 relationship |
| --- | --- |
| Final Combat | Full painted indigo crypt, statues, banners, candlelight, substantial arena, centered full-body Shadeling with warm lantern, framed stats, green complete ribbon, four-by-four board, wiring tools, detailed three-card hand, piles, forecast, turquoise pointed Cast and icon navigation now form the same visual hierarchy. There is no flat environment blockout or question-mark substitute. |
| Home | Cold indigo stone and warm gold/candle accents remain compatible. Turquoise primary material and navy secondary material retain the reference's functional color distinction. The rebuilt frames are cleaner and more geometric than the worn painted reference; compatibility does not mean pixel identity. No Home composition is rebuilt here. |
| Map | Navy/cream/gold icon and lettering choices remain compatible with parchment. The small single-ink Spark study retains its recognizable sun silhouette without hue. No extra legend strip or Map redesign is introduced. Actual placement/import on the Map screen remains untested. |
| Menu | Turquoise primary and shared navy secondary states, gold trim and outlined serif labels follow the Resume versus Options/Shop/Quit treatment. Small state details remain visible in the dedicated sheet, including grayscale. This is component compatibility, not a rendered dimmed Menu acceptance test. |

The typography is the actual acquired Noto Serif variable font documented in the [r002 provenance record](../r002/type-geometry/font-provenance.json), not the rejected r001 Open Sans layout fallback. The official final reference's illustrative BOSS/infinity/value examples are permitted by the visual contract; they are not evidence of changed production balance or finite-stock rules.

## Revised exported-file inspection

Reinspected the revised [841×1870 main](../../../../output/art/rc-011/r004/pilot-841x1870.png), [450×1000 reduced preview](../../../../output/art/rc-011/r004/pilot-450x1000.png), [native 360×640](../../../../output/art/rc-011/r004/pilot-360x640.png), [native controls companion](../../../../output/art/rc-011/r004/pilot-360x640-controls.png), [state sheet](../../../../output/art/rc-011/r004/pilot-states.png), [grayscale state sheet](../../../../output/art/rc-011/r004/pilot-states-monochrome.png), [137/72 px tile states](../../../../output/art/rc-011/r004/pilot-tile-states.png) and [type sheet](../../../../output/art/rc-011/r004/pilot-type.png). These are direct visual inspections of exported PNGs, not conclusions from the generation prompt. The 450 px image is a reduced overview; the separate 360 px exports are the native-size scrolling layout study.

All eight defects reported from the first render are visibly resolved in the revised exports:

1. The full floor/location label fits before the pause frame.
2. Infinity stock uses visible vector geometry; scroll captions use supported wording without missing-glyph boxes.
3. Native 72 px cells show the complete route, branch values, TEMP badge and End total 12.
4. The rotated 90/270-degree Spark state paths have upright labels and values positioned away from the vertical path.
5. Free Spark's separate TEMP badge leaves damage 6 visible.
6. Native Split and Join have distinct branching geometry.
7. Native bottom navigation has 50 px control bounds and fits the lower edge of its companion view. This is a drawn size check, not an input test.
8. The type sheet now labels body/status as semibold, matching weight 600.

Main circuit paths have no flow arrowheads, and only Remove/Rotate remain as editing actions. The Rotate icon's curved arrow correctly represents an action. No removed Flip/Undo/Inspect/Cancel/Details-Pass rows were seen. The main includes all three detailed cards and explicit Draw/Discard and forecast fields.

The painted tile, navy panel and Cast materials replace the initial flat faces. Card rims preserve amber Spark, green Shield and violet Focus. Draw/Discard names and counts fit independently of the card descriptions. Costs and numerals remain readable in the full overview. The native controls companion uses a horizontal hand-scroll study with one detailed card and both piles visible; it does not claim three cards fit simultaneously in 360 px.

Powered tile ports have circular collars, while unpowered paths remain plain, providing a non-color cue without arrowheads. Selected check, focused dashed perimeter, invalid cross and unavailable information badge remain distinct at both 137 and 72 px. Combined focus/selection and focus/unavailability survive the grayscale sheet. Begin's check/full ring and End's diamond/lower ring opening remain distinguishable. The sun silhouette is still identifiable at the displayed 24/32/48 px grayscale samples.

The final minor correction is also visually verified: the north wire now stops at the Join cell's top border, leaving JOIN clear in both the 841 px main and native 360 px export. No remaining clipping, missing-glyph, removed-control or title/route overlap blocker was found in these inspected images.

## Limits and remaining style differences

The recreated actor, materials, frames, symbols and type are new assets; they do not exactly duplicate every brush mark in the approved flattened reference. The revised actor placement/scale closely matches the reference, with full feet, cloak and lantern visible. The repeated tile bevels, flat vector resource/navigation details and regular sun rays remain more geometric than the approved painted forms. The new primary turquoise and navy secondary materials have visible texture and the appropriate color roles, although individual highlights and edge wear differ. The title uses Noto Serif with mixed case rather than reproducing the reference's exact small-cap letterforms.

This is a complete assembled visual candidate, not proof of implemented undirected rules, hit targets, scrolling/input behavior or device font rendering. No Home, Map or dimmed Menu gameplay scene was rebuilt or tested. Owner approval of this candidate remains unrecorded.
