# RC-012 core symbol library

October 11, 2026 · source revision r001. Twenty-four precise editable SVG masters and byte-identical runtime exports follow the current [clean-board visual contract](../../docs/gameplay-visual-contract.md). The supplied reference is owner-approved; these normalized vector adaptations are neither separately owner-approved nor claimed to be pixel-identical.

The full machine-readable inventory is [core_symbols.json](core_symbols.json). It records every exact source/export path and hash, retained-source hashes, geometry, consumers, port boundaries, import recipe and provenance. [The usage guide](../../docs/core-symbols-and-typography.md) combines these with the font package and actual Godot preview results.

| Stable manifest ID | Editable masters, relative to this directory | Runtime exports, relative to `assets/icons/` | Count |
| --- | --- | --- | --- |
| `circuit_geometry` | `circuit/{begin,end,straight,corner,split,join}.svg` | Same relative paths | 6 |
| `rune_symbols` | `runes/core/{spark,shield,focus,conjure}.svg` | Same relative paths | 4 |
| `temporary_marker` | `temporary_marker.svg` | Same relative path | 1 |
| `navigation_icons` | `navigation/{menu,map,guide,sound_on,sound_off}.svg` | Same relative paths | 5 |
| `editing_icons` | `editing/{remove,rotate}.svg` | Same relative paths | 2 |
| `resource_icons` | `resources/{health,energy,attack,draw_pile,discard_pile,pause}.svg` | Same relative paths | 6 |

Draw and Discard have separate established pilot emblems and live labels/counts. Pause serves the explicitly retained top pause control. No Close or retired editing controls were added. Later rune/relic/room/intent/progression batches remain RC-041.

## Geometry and placement

Every SVG has `viewBox="0 0 128 128"`, width/height 128, top-left origin, and pivot `(64,64)`. Decorative art stays within `[16,16,112,112]` including outlines. Named `outline`, `fill` and `detail` groups expose the primary silhouettes, facets and remaining detail; glyphs have no fonts, live labels, embedded bitmap, filters, external links or hidden dependencies. The primary silhouette group may include its base fill so that its dark edge is directly editable.

Ports are exactly `N(64,0)`, `E(128,64)`, `S(64,128)`, `W(0,64)`. Straight is `M0 64H128`; Corner is `M0 64H64V128`. These two connection exports intentionally reach the true cell edge, outside decorative safe bounds. Both are blunt, undirected strokes with no arrowhead. Their normalized main width is **8**, yielding 1.5/2/3 logical pixels at 24/32/48-pixel glyph size and 4.5/8.5625 at 72/137-pixel cells. The first Godot contact-sheet inspection showed that the initial thinner stroke lost visual weight at 24/32; 8 is the revised production value. Drawn matching segments use `8*cell_side/128`. Toolbar consumers inset the whole connection SVG; the board renderer owns gap bridging and must not move the ports inward.

The other circuit symbols and all rune symbols are **decorations**. Their tips are never connector data. Render connections on a separate layer, leaving each active edge channel clear by at least 10 normalized units on either side. Reuse existing endpoint orientations only as art recipes: Begin E, End N; Spark/Shield W+E. Focus and Conjure are techniques and have no board ports. These are not claims that the current directed evaluator has been migrated.

Split retains the exact r006 path `M10 50H42 M42 50L78 13 M42 50L78 87`, transformed with `translate(15.6 9) scale(1.1)`. Join retains `M14 20V46L50 66L86 46V20 M50 14V91` and its diamond cap, transformed with `translate(12.5 11.7275) scale(1.03)`. The r006 silhouettes are uniformly normalized, with no reinterpreted Y/T substitute. **Split and Join logical ports are intentionally null in the production metadata**, pending explicit undirected evaluator/graph decisions. Their three/four visible tips do not define logical degrees or direction.

Clockwise quarter-turns rotate positions around `(64,64)` using `N→E→S→W→N`. Connection layers rotate independently from glyph decoration and upright live labels. Retain Begin's check and End's diamond as distinct identities; never overlay them. Only BEGIN and END are board text. Spark/Free Spark share the exact same board glyph and never show names, values, costs, totals or a temporary badge there.

## Palette and reusable states

Color exports preserve the pilot's warm sun, green shield, violet Focus, turquoise endpoints/Split, gold Join/tools/navigation, red health/attack and blue energy. Conjure adds a violet cupped-hand/creation-star motif using that palette. Its content identity comes from live card text. The hourglass applies only to Free Spark hand/detail/Guide lifetime context with live wording; it is forbidden on the clean board.

[The editable shader](symbol_tint.gdshader) and [runtime copy](../../assets/icons/symbol_tint.gdshader) avoid duplicate SVG geometry. `appearance_mode=0` uses original color, `1` produces luminance monochrome while preserving dark edges and facets, and `2` produces a flat alpha silhouette using `ink`. Mode 1 is the working monochrome recipe, interpolating between `monochrome_paper` and `ink` by source luminance. On dark backgrounds use light ink and default black paper; on parchment use dark ink `#111b29` and light paper `#e8d5aa`. Direct dark-ink multiplication collapsed the endpoint/book interior detail in the first Godot sheet; the two-tone luminance mapping preserves that detail. Mode 2 is a supplemental one-color silhouette diagnostic; it intentionally loses internal facets, including book/question-mark differentiation, so retain the live labels and use mode 1 when that detail matters. `ink` also controls opacity. Vertex modulation is captured before fragment texture multiplication.

Consumer overlays provide selection outline/check, dashed keyboard-focus outline, disabled opacity plus label/treatment, unavailable slash plus live availability, and invalid cross plus live explanation. Preserve combined selected+focused and unavailable+focused treatment. These overlays are independent from the glyph and therefore do not multiply runtime SVG files. Color is supplemental to shape and live text.

## Provenance and rebuild

[The builder](../../tools/build_core_symbols.py) reads only the retained r006 pure icon-authoring function and SVG nodes; it never runs the historical composition builder. Begin, End, Spark, Split, Join, Shield, Focus, health, crystal, attack, navigation, editing, pause and pile motifs adapt those explicit vector constructions. Sound off shares the retained speaker with an original cross. Conjure, the temporary hourglass and precise edge wires are original local RC-012 vector authoring. No screenshot pixels or external icon set were used, and no raster artwork was generated.

Retained dependencies, including their SHA-256 values, are recorded in `core_symbols.json`: `source-assets/pilot/revisions/r006/build_review.py` and `ui/{spark,split,join}.svg`. They remain byte-unchanged. Source vectors were constructed for this project; no third-party icon licence is introduced. Reference provenance and approval do not by themselves establish separate shipping-rights clearance; RC-050 retains the final shipped-asset audit. No generation model/seed has been invented for vector construction.

Rebuild with `python tools/build_core_symbols.py` from the repository root. The builder copies each editable source to its designated runtime SVG and copies the editable tint shader. It writes [focused source checks](../../output/qa/rc-012/symbol_source_validation.json). The standalone source renderer [inspect_symbol_sources.cjs](../../output/qa/rc-012/inspect_symbol_sources.cjs) uses the configured bundled Sharp path and writes [the source-only study](../../output/art/rc-012/symbol-source-study.png) plus [measured alpha bounds](../../output/qa/rc-012/symbol_alpha_bounds.json). This external renderer is supplementary; it does not establish Godot import acceptance.

## Import and evidence boundary

The isolated Godot preview imports SVGs at `svg/scale=2`, yielding 256×256 pixels, lossless compression, mipmaps off, and linear filtering. The conservative decoded RGBA8 estimate for all 24 is **6 MiB**; it excludes font atlases, renderer buffers and transient copies. At default 128px rasterization the corresponding estimate would be 1.5 MiB. Masters stay excluded through `source-assets/.gdignore`; evidence stays under `output/.gdignore`. Source/runtime equality refers to the SVG and shader bytes, not engine-generated import metadata.

Focused source checks pass: 24 plain-vector XML files, exact source/export equality, no linked resources, named layers, and all four retained dependencies unchanged. The supplemental 256px alpha scan passes all decorative safe bounds, with explicit connection-edge exceptions. [Four-quarter-turn edge checks](../../output/qa/rc-012/symbol_rotation_geometry.json) pass for all six circuit assets: Straight/Corner contact only their rotated exact edges, and the four decorative circuit glyphs contact no edge. The inspected source sheet covers each glyph at 128/48/32/24 pixels; Begin/End, sound on/off, eraser/rotation, and the exact fork/trident remain distinguishable. Conjure and Draw pile remain recognizable at 24 pixels but fine internal details soften; use 32/48 pixels where those details matter and retain their live labels.

Actual engine import/render results and four-rotation, state, background and responsive text checks are recorded in the shared RC-012 verification and usage documents. Full gameplay integration, shared UI theme binding, undirected evaluator/control migration and physical-device verification remain separate. This library does not change gameplay rules, circuit degree, branch aggregation, cycles, repeated triggers or no-cast turn ending.
