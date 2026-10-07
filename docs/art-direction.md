# Rune Cast art direction

The four [approved visual references](visual-reference.md) for Home, Combat, Map, and Menu are the final visual targets for the production UI, confirmed October 8, 2026. Exact user-supplied images are stored in `output/imagegen/approved/`. The working Godot screen uses intentionally simple vector placeholders so gameplay can be tested first.

Preserve the Menu's turquoise Resume button and matching navy Options, Shop, and Quit buttons. Preserve the Map's parchment route without a legend strip and its Menu, Map, Guide, Sound navigation. The Home screen uses the illustrated moonlit tower and Continue, New Run, Options buttons.

## Visual language

Use strong dark outlines, angular silhouettes, broad matte colour shapes, and simple painted shadows. Environments use muted indigo and blue stone, warm candlelight, and restrained gold frames. Magic and actions use brighter amber, turquoise, green, and violet.

Keep the full-body enemy centered in a side-view arena. Show intent above the enemy and health beneath it. Do not add a visible player character.

The board must stay readable at phone size. Keep cell boundaries, ports, direction arrows, effect values, and selection states clear. Colour supports recognition but should not be the only way to distinguish components.

## Asset production

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

1. Approve one enemy, one rune tile, and one button as a matching style set.
2. Produce separate environment and enemy assets.
3. Build reusable UI frames and symbols.
4. Test outlines, contrast, and readability at phone size.
5. Add enemy reactions, cast pulses, and audio.
6. Verify Android and iOS device layouts.

Do not crop the complete mockup into a single game background. Never bake health, energy, rune values, button labels, or circuit paths into finished background art.

## Placeholder palette

- Background: #0C1525
- Surface: #17273B
- Trim: #96784D
- Text: #EEE0BF
- Active connection: #FFC76B
- Source and terminal: #5BE5D2
- Shield: #82D6A0
- Technique: #BA9BEF

The inventory in asset-inventory.csv tracks what is reference material, a placeholder, or still needed. Final character animations, music, and production sound effects have not been generated.

The [v1 specification](v1-design-spec.md) and [content roster](content-roster.md) bound production to five character packs, one layered crypt with simple lighting variants, separate Home art, reusable UI/map assets, core effects/SFX, two music loops and ambience. Shadeling is proposed as the introductory normal enemy; its reference label is not a guardian commitment. RC-010 owns the full manifest expansion and production contracts. Screen behavior belongs to RC-025/RC-028/RC-032, with complete art integration in RC-042.

