# RC-011 independent context audit

October 10, 2026. Read-only review of the current production contracts, content witnesses and UI implementation. No Git operations, game edits, gameplay reruns, imports, physical-device checks or owner acceptance were performed by this audit.

## Images actually inspected

- All four approved references: `output/imagegen/approved/{combat,home,map,menu}.png`.
- `output/qa/rc-009/final-production.png` (450×1000).
- `output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/unavailable-stock.png` (720×1600).
- `output/qa/rc-008/touch-capture-1791519954-3060/selected-rotated-endpoint.png` (720×1600).
- `output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/small-portrait-inspector.png` (360×640).

The approved references consistently use strong dark outlines, broad angular matte shading, indigo/navy material, warm amber light, restrained gold, turquoise primary actions and navy secondary actions. Menu Quit shares the navy secondary treatment. The parchment Map uses dark silhouettes and no encounter-legend strip. The historical Combat image's BOSS label, infinite stock, Free Spark setup and older displayed health/turn values do not describe the current Training witness.

## Exact composition witness

Authoritative sources: `data/board_examples.json`, `data/runes.json`, `docs/board-catalog.md` and the current UI controls. This is a deliberately selected reproducible **built example**, not a prefill or guaranteed opening hand.

| Field | Training seed294, built |
| --- | --- |
| Player / energy / turn | 30/30 HP; 3/3 energy; turn1 |
| Enemy | Shadeling32/32; ATTACK8; normal introductory enemy |
| Circuit | Begin cell0 rotation0 → Spark cell1 rotation0 → End cell2 rotation3 |
| Forecast | Cost2; damage6; shield0; expected incoming8 |
| Kit | Extra Branches; remaining Straight4/4, Corner2/2, Split2/2, Join2/2 |
| Hand | Spark UID3 (value6, cost2); Focus UID5 (draw2, cost1) |
| Ownership | Spark UID0 is installed; hand2 / draw5 / discard0 |
| Endpoint opening | Begin0 rotation2 outputW; End2 rotation3 inputW; fourteen empty cells |
| Opening hand | Spark UID0, Spark UID3, Focus UID5 |

Cells are zero-based row-major. Begin rotation0 has outputE. End rotation0 has inputN. Spark rotations0/1/2/3 are W→E / N→S / E→W / S→N, with upright labels. Free Spark uses the same symbol, value6 and cost0, plus a separate temporary badge; it is not part of the Training witness. Focus and Conjure are techniques and have no board ports. Conjure costs0 and creates one temporary Free Spark. End displays aggregate damage6 on the completed Training witness.

## Layout and interaction facts

- Design720×1600; current desktop override450×1000. Main margins18; vertical gap6. Board cells137 and gaps6 make a566-square grid. At native360 viewport the formula `min(137,floor((width-70)/4))` gives72-square cells, total306.
- Arena minimum310 high, drawing coordinates680×300. Proposed actor foot `(340,233)` in these coordinates;512 texture foot `(256,448)`; scale0.46, comparison0.42–0.48. Actor must remain uniformly scaled.
- Below board: Straight/Corner/Split/Join stock row; Rotate/Flip/Undo/Erase (58 high); Inspect/Cancel selection/Details / Pass; compact hand; status; Cast; Cast ends turn; Menu/Map/Guide/Sound. Cancel selection shortens to Cancel at viewport width below500. No permanent forecast strip is added.
- Buttons have66×50 minimum rectangular targets. Hand cards142×92 minimum; horizontal scroll area104 high. Status minimum46; Cast64 high with28px text. Stock/tool labels15px; board labels14px; general UI20px.
- Inspector spans x4–96% and y12–88%; content padding18; title28px; body23px. Body scrolls independently and fixed Close/Pass actions are64 high. Techniques have no Activate action in their inspector.
- Selecting an endpoint clears placement and permits Rotate; Flip stays unavailable. Flip only reverses Straight/Corner wires. Undo reflects real edit history. Erase cannot erase endpoints.
- Stock0/6 remains inspectable and selectable; same-kind connector replacement remains legal even when no spare stock exists. Eligible `+` means legal placement, not a guaranteed affordable/damaging circuit. Protected/unavailable cells show `x` and explanation. The runtime exhausted-stock screenshot has both + on existing Straight pieces and x on protected/empty cells.
- The actual narrow inspector screenshot visibly crops/scrolls body text while Close stays fixed. A native360×640 study must show viewport scroll boundaries instead of shrinking the tall composition.

## Delivery constraints

Shadeling source1024² and export512², source foot `(512,896)`, export foot `(256,448)`, neutral bounds approximately x80–432/y88–448 and motion envelope x32–480/y32–480. Body/cloak, lantern arm, lantern and flame must be real separate editable layers; shadow/light/glow separate where used. All part exports retain full shared canvas/origin.

Tile source512²/export256²; slices16 export pixels on all sides. Spark SVG128² viewBox, essential art16–112, provisional outline8/internal6, exact edge ports N(64,0),E(128,64),S(64,128),W(0,64). Base frame cannot imply connections. Glyph, temporary badge, states, paths and live text are separate.

Button source1024×256/export512×128; slices24 left/right and20 top/bottom. Labels remain live. Compact inset must fit66×50 controls; large actions64 high and wide Home/Menu proportions also require checks. State overlays may be reused; seven states plus focus+selection and focus+unavailable must be shown with shape cues.

Recommended candidate direction in the brief is Noto Serif SemiBold (headings/large actions), Noto Sans Regular (body) and Noto Sans SemiBold (compact labels/values). They were unacquired/unlicensed in RC-010. Any new licence claim requires actual obtained evidence. If unavailable, use the current engine fallback for size checks and label the candidate provisional.

Only the four `pilot_*` manifest rows can gain source evidence. `source_ready` requires editable sources, provenance and previews; keep `runtime_path_state=source_only`, `visual_direction_status=reference_guided`, and rights unresolved absent actual rights evidence. `approved_reference` is restricted to reference rows. Master paths must remain those in the brief/manifest. `.gdignore` provides source import exclusion; export presets remain untouched.

Decoded RGBA8 texture estimates:512²=1MiB,256²=0.25MiB,512×128=0.25MiB each. Count actual unique layers/overlays, excluding source-only contact sheets from proposed runtime totals; never use compressed PNG byte size as decoded memory.

The asset-plan validator checks schema, paths, links, ownership/cycles, counts, historical pairs and protected hashes. It writes the existing RC-010 validation-report destination. It does not inspect actual ORA layers, alpha, slice rendering, ports, licensing, Godot imports, device readability or artistic quality. Those require separate truthful review evidence.
