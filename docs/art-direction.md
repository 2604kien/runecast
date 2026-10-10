# Rune Cast art direction

The four [approved visual references](visual-reference.md) for Home, Combat, Map, and Menu are the final visual targets for the production UI, confirmed October 8, 2026. Exact user-supplied images are stored in `output/imagegen/approved/`. The working Godot screen uses intentionally simple vector placeholders so gameplay can be tested first.

Preserve the Menu's turquoise Resume button and matching navy Options, Shop, and Quit buttons. Preserve the Map's parchment route without a legend strip and its Menu, Map, Guide, Sound navigation. The Home screen uses the illustrated moonlit tower and Continue, New Run, Options buttons.

## Visual language

Use strong dark outlines, angular silhouettes, broad matte colour shapes, and simple painted shadows. Environments use muted indigo and blue stone, warm candlelight, and restrained gold frames. Magic and actions use brighter amber, turquoise, green, and violet.

Keep the full-body enemy centered in a side-view arena. Show intent above the enemy and health beneath it. Do not add a visible player character.

The board must stay readable at phone size. Keep cell boundaries, ports, direction arrows, effect values, and selection states clear. Colour supports recognition but should not be the only way to distinguish components.

## Asset production

The [asset manifest](asset-inventory.csv) is the authoritative bounded inventory. The [production specification](asset-production-spec.md) defines source/runtime paths, dimensions, anchors, exact circuit geometry, shared states, delivery evidence and provisional budgets. The [RC-011 matching pilot brief](style-pilot-brief.md) gives the next production task its concrete Shadeling/Spark/button deliverables and review criteria. These RC-010 technical contracts are proposed production defaults; the approved screen direction is already settled, while pilot and device validation remain later work.

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

1. Produce and review Shadeling, one Spark tile treatment, and one reusable button as the matching RC-011 style set, using all four approved references and current runtime scales.
2. Produce separate environment and enemy assets.
3. Build reusable UI frames and symbols.
4. Test outlines, contrast, and readability at phone size.
5. Add enemy reactions, cast pulses, and audio.
6. Verify Android and iOS device layouts.

Do not crop the complete mockup into a single game background. Never bake health, energy, rune values, button labels, or circuit paths into finished background art.

### Production conventions

- Keep editable source masters in `source-assets/`, separated from runtime exports under `assets/`. Use layered `.ora` exchange masters for painted art, retain raw generation/application-native originals, and use editable SVG for symbols. Godot controls supply labels, values, bars, paths and input behavior. The [general contract](asset-production-spec.md#general) defines revisions, imports and source exclusion from builds.
- Pilot exports stay under `source-assets/pilot/exports/` until RC-012/RC-013/RC-014 adopt and refine the appropriate pieces. A runtime-format PNG, SVG or preview is not proof of runtime readiness, integration, licensing or device acceptance. Preserve source/creator, prompt/model records where known, refinement history and unresolved rights in delivery notes.
- Proposed characters use a 1024×1024 source and 512×512 transparent export, with shared foot anchor `(256,448)` in export coordinates. The [character contract](asset-production-spec.md#characters) defines framing, scale and four-state needs; the pilot tests the lean pose-plus-transform method before final pack production.
- Decorative paint must leave precise [edge-port geometry](asset-production-spec.md#circuit-icons), upright text and shared selection/focus/invalid/temporary/placement markers readable. Validate sockets at the current 137-pixel cell size and the 72-pixel cells of the native 360-wide test viewport. Neither larger source art nor a full-screen reference proves small-size legibility.
- Use shared scalable frames and live text. The [UI contract](asset-production-spec.md#ui-typography) covers normal, pressed, focused, selected, disabled, invalid and relevant unavailable states, plus typography and RC-008 inspector compatibility. An exhausted connector remains inspectable; a decorative border must not hide its count or intercept a control's touch area.
- The four board IDs reuse one socket/circuit system and one crypt layer set. Three lighting presets (base cool, warm candle/recovery, dark guardian) reuse that art; they do not require four painted boards or environments. Home retains its separate tower illustration; Map uses reusable parchment with live route/node overlays.

Current production uses random distinct Begin/End cells, player Rotate/Undo and finite connector kits. The approved Combat image's fixed arrangement, infinity symbol and BOSS label do not override those accepted rules or Shadeling's introductory normal-enemy role. Preserve the current Inspect, Cancel selection, Details / Pass, stock feedback and scrolling behavior described in [touch interactions](touch-interactions.md); visual refinement does not remove them to imitate an older mockup.

## Placeholder palette

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

