# Rune Cast art direction

The [approved visual references](visual-reference.md) are the final visual targets for production UI. Combat now uses the owner's [approved final v2 gameplay image](../output/imagegen/approved/combat-final-v2-clean-board.png), preserved from the latest attachment exactly. Home, Map and Menu retain their existing approvals. Older `combat.png`, `combat-final.png` and generation history remain preserved. The working Godot screen still contains placeholders and older controls.

The latest approved board has **Begin and End labels only**, with no other slot names, rune/path/End values, cost badges or TEMP. Use the image's sideways-fork Split and upright-trident Join on the board and toolbar. Cards, toolbar stock/names, piles and the external information bar retain their content. The [r006 editable pilot](../source-assets/pilot/revisions/r006/delivery.md) applies these corrections; r004 is preserved as source/method history.

The current matching-preview scope covers the **entire Combat screen**, including the painted crypt and all supporting UI, with no placeholders. The previous three-asset pilot scope and blockout allowance are superseded. Follow the [gameplay visual contract](gameplay-visual-contract.md) for the full-screen composition and the distinction between approved design and implemented runtime behavior.

Preserve the Menu's turquoise Resume button and matching navy Options, Store, and Quit buttons. The owner's October 12 clarification renames the reference's Shop label to **Store**: this opens the separate item Store, not a shop room. Entering a shop room displays that room as the main screen. Preserve the Map's parchment route without a legend strip and its Menu, Map, Guide, Sound navigation. The Home screen uses the illustrated moonlit tower and Continue, New Run, Options buttons.

## Visual language

Use strong dark outlines, angular silhouettes, broad matte colour shapes, and simple painted shadows. Environments use muted indigo and blue stone, warm candlelight, and restrained gold frames. Magic and actions use brighter amber, turquoise, green, and violet.

Keep the full-body enemy centered in a side-view arena. Show intent above the enemy and health beneath it. Do not add a visible player character.

The board must stay readable at phone size. Keep cell boundaries, connecting ports and selection states clear; values remain in cards and the external forecast. Circuit strokes have no directional arrowheads. Split/Join use the approved fork/trident silhouettes without directional port semantics. Colour supports recognition but should not be the only way to distinguish components.

Use Remove and Rotate as the only circuit editing actions. Remove Flip, Undo, Inspect, Cancel selection and Details / Pass from the requested editor UI. Preserve the detailed hand cards, flanking draw/discard piles, action log, damage/shield/cost/incoming info bar above Cast, pointed turquoise Cast button and illustrated bottom navigation shown in the final reference.

## Asset production

The [RC-013 theme and wordmark guide](ui-theme.md) records the production adoption of those painted materials into reusable frames, detailed cards, pointed primary controls, shared states, dialogs and the separate in-game Rune Cast logo. The final [Theme resource](../assets/ui/rune_cast_theme.tres), [live component factories](../scenes/ui/theme/components.gd), [transparent wordmark](../assets/ui/wordmark.png) and [editable production sources](../source-assets/ui/delivery.md) are delivered and isolated imports/renders are verified. Ordinary text remains live and RC-012 fonts/icons are reused. Its isolated Home/Menu/Map/Options specimens establish presentation coverage; the guide and [verification record](verification.md#october-12-2026--rc-013-reusable-theme-and-wordmark) distinguish technical import results, inherited generated-art rights, main-game integration and physical-device acceptance. RC-016A remains the gameplay/control migration gate.

The [RC-012 production symbol and typography library](core-symbols-and-typography.md) adopts24 editable SVGs and the actual Noto Serif 2.015 variable font from the retained pilot: width 100, weight 700 for headings/large actions,600 for labels/values and500 for location. [Editable symbol sources](../source-assets/icons/), [runtime symbols](../assets/icons/), [font role resources](../assets/fonts/) and isolated Godot evidence are linked by the guide. The library keeps outlined serif text live, clean board cells, the exact fork/trident silhouettes, Remove/Rotate and separate supporting pile/Pause/navigation symbols. It does not create the game logo or change the main game's theme.

The [r006 pilot](../source-assets/pilot/revisions/r006/delivery.md) supplies the current full Combat composition, using retained r004 painted crypt, stone tiles, navy panels and pointed turquoise Cast. Preserve those painted materials, distinct gold edge planes, dark indigo recesses and live outlined serif labels when developing RC-012/RC-013. The retained r002 actor supplies the crooked hood, compact masked face, broad ragged cloak, gold chain and lantern at the reference arena scale. Current state and native narrow sheets use the clean board and corrected symbols; prior full-screen previews remain revision history.

The [asset manifest](asset-inventory.csv) is the bounded inventory. The [production specification](asset-production-spec.md) defines source/runtime paths, dimensions, anchors, exact circuit geometry, shared states, delivery evidence and provisional budgets. The [RC-011 matching pilot brief](style-pilot-brief.md) records the earlier Shadeling/Spark/button work; its limited scope does not exempt the current full-screen preview from matching the crypt or supporting UI. These RC-010 technical contracts are proposed production defaults, subordinate to the latest [gameplay visual contract](gameplay-visual-contract.md) where direction or controls conflict. The visual target is settled; production, integration and device validation require separate evidence.

| Asset | Method | Delivery |
| --- | --- | --- |
| Enemy and boss illustrations | Image generation followed by art refinement | Separate transparent PNGs, with consistent scale and foot anchor |
| Crypt environment | Painted/generated scene, refined into layers | Background, floor, and optional foreground PNG layers |
| Home tower | Separate painted/generated illustration following approved Home composition | Source master and portrait runtime background; no baked controls; RC-015 |
| Home logo and reusable menu states | Refined in-game wordmark and Godot theme | Separate logo layer plus live button labels and states; RC-013; distribution identity RC-051 |
| Parchment route | Reusable parchment, node symbols and connection treatments | Separate art and live route overlays; RC-041; behavior RC-025 |
| Rune and navigation symbols | Precise vector drawing | Editable SVG source and tested runtime imports |
| Wire and circuit geometry | Godot drawing code or exact vector shapes | Consistent edge port coordinates |
| Frames and buttons | Reusable painted or vector frames | PNG/SVG and Godot themes; scalable borders |
| Text, values, bars | Godot controls | Runtime text and state, not baked into artwork |
| Motion and spell effects | Godot animation and particles | Editable scenes and resources |

Blender is optional for future rigged models, rendered sprites, or 3D scene references. It is not required for the 2D foundation.

## Production order

1. Match the entire Combat preview to the official final gameplay image, including the complete painted crypt, Shadeling, board, cards, piles, info bar, Cast and supporting navigation; no placeholders.
2. Produce separate environment and enemy assets from that settled visual direction.
3. Build reusable UI frames and symbols, using undirected connection geometry and the approved Remove/Rotate editor controls.
4. Test outlines, contrast, and readability at phone size.
5. Add enemy reactions, cast pulses, and audio.
6. Verify Android and iOS device layouts.

Do not crop the complete mockup into a single game background. Never bake health, energy, rune values, button labels, or circuit paths into finished background art.

### Production conventions

- Keep editable source masters in `source-assets/`, separated from runtime exports under `assets/`. Use layered `.ora` exchange masters for painted art, retain raw generation/application-native originals, and use editable SVG for symbols. Godot controls supply labels, values, bars, paths and input behavior. The [general contract](asset-production-spec.md#general) defines revisions, imports and source exclusion from builds.
- Pilot exports stay under `source-assets/pilot/exports/` until RC-012/RC-013/RC-014 adopt and refine the appropriate pieces. A runtime-format PNG, SVG or preview is not proof of runtime readiness, integration, licensing or device acceptance. Preserve source/creator, prompt/model records where known, refinement history and unresolved rights in delivery notes.
- Proposed characters use a 1024×1024 source and 512×512 transparent export, with shared foot anchor `(256,448)` in export coordinates. The [character contract](asset-production-spec.md#characters) defines framing, scale and four-state needs; the pilot tests the lean pose-plus-transform method before final pack production.
- Decorative paint must leave precise [edge-port geometry](asset-production-spec.md#circuit-icons), upright text and shared selection/focus/invalid/temporary/placement markers readable. Validate sockets at the current 137-pixel cell size and the 72-pixel cells of the native 360-wide test viewport. Neither larger source art nor a full-screen reference proves small-size legibility.
- Use shared scalable frames and live text. The [UI contract](asset-production-spec.md#ui-typography) covers normal, pressed, focused, selected, disabled, invalid and relevant unavailable states, plus typography. Its older RC-008 inspector requirements are historical where they conflict with the October 11 editor changes. A decorative border must not hide a stock count or intercept a control's touch area.
- The four board IDs reuse one socket/circuit system and one crypt layer set. Three lighting presets (base cool, warm candle/recovery, dark guardian) reuse that art; they do not require four painted boards or environments. Home retains its separate tower illustration; Map uses reusable parchment with live route/node overlays.

The runtime still uses the earlier directed circuits and controls. The owner has explicitly approved undirected validity and removal of Flip, Undo, Inspect, Cancel selection and Details / Pass, leaving Rotate and Remove. [RC-016A](project-plan.md#rc-016a--undirected-evaluator-and-control-migration-gate) owns evaluator/control migration and its unresolved aggregation, cycle, repeated-trigger and no-cast decisions before RC-016 full integration. Saving artwork does not implement these changes. Keep random distinct Begin/End generation, finite kits and Shadeling's normal-enemy role unless separately changed. The reference's fixed arrangement, infinity symbol, BOSS label and example numbers are illustrative. The older [touch interactions](touch-interactions.md) remain implementation history where they conflict with the new contract.

## RC-011 r001 visual rejection — October 11, 2026

The owner rejected the [r001 pilot](../source-assets/pilot/delivery.md) for failing to match the approved gameplay reference. Its [composition — retired in authorized cleanup](asset-cleanup.md) is retained as rejected evidence. Shared indigo, gold and turquoise colours were insufficient: character proportions/detail, scale, frame construction, Spark prominence, Cast silhouette and typography materially diverged. The previous selection of this visual direction is withdrawn. The existing approved images are the fixed target.

Revision must use the reference's compact broad Shadeling, bold cartoon contour and broad matte cloak planes; substantial sculpted gold bevels; large amber sun on a brown rune face; pointed turquoise Cast; and cream serif labels/values. Font names and provisional technical dimensions are subordinate to the rendered reference match. [Fallback evidence — retired in authorized cleanup](asset-cleanup.md) remains a layout test only. Layer separation, independent state geometry and [hierarchical motion — retired in authorized cleanup](asset-cleanup.md) remain technically useful, without adopting r001's appearance.

**Historical r001 outcome: visual revision required.** Structural validation is distinct from visual matching. Dependent production must not use the rejected r001 appearance as an approved baseline. That artwork correction did not change runtime mechanics or approve the historical BOSS/infinity labels. The later explicit undirected-circuit and editor changes are recorded above.

The historical [r002 correction](../source-assets/pilot/revisions/r002/delivery.md) has a reference-guided broad Shadeling at larger scale, warm amber Spark with long rays, stronger frame bevels, pointed Cast and actually rendered Noto Serif. Those improvements did not produce an exact full-screen match. Its labelled crypt blockout and unfinished supporting symbols do not meet the expanded October 11 scope and are not an approved final appearance. The official final target is now [combat-final.png](../output/imagegen/approved/combat-final.png); adopting that visual reference does not make the older pilot production assets or runtime complete.

## Historical foundation placeholder palette

These values document the playable foundation. They are not permission to use placeholder paint or simplified UI in the current matching preview.

- Background: #0C1525
- Surface: #17273B
- Trim: #96784D
- Text: #EEE0BF
- Active connection: #FFC76B
- Source and terminal: #5BE5D2
- Shield: #82D6A0
- Technique: #BA9BEF

The manifest distinguishes approved visual references, existing placeholders and planned deliverables from source-ready, runtime-ready, integrated and device-verified assets, using the vocabulary in the [manifest guide](asset-manifest-guide.md#readiness-and-approval-vocabulary). Final character animations, music, and production sound effects are still planned; RC-010 does not generate them.

The [v1 specification](v1-design-spec.md) and [content roster](content-roster.md) bound production to five character packs, one layered crypt with simple lighting variants, separate Home art, reusable UI/map assets, core effects/SFX, two music loops and ambience. Shadeling is proposed as the introductory normal enemy; its reference label is not a guardian commitment. RC-010 supplies the manifest and contracts; RC-011 validates the matching pilot before production. Screen behavior belongs to RC-025/RC-028/RC-032, with complete art integration in RC-042. [Delivery acceptance](asset-production-spec.md#delivery-acceptance) and [performance budgets](asset-production-spec.md#performance-budgets) keep desktop preview, import/integration and physical-device evidence separate.

