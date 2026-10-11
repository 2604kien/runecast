# RC-011 button and painted tile material delivery

Revision **r001**, source production and structural checks recorded **October 11, 2026**. **Owner rejected visual fidelity; revision required.** The earlier shared-style pass is withdrawn. These isolated candidates do not establish Godot import/integration, touch behavior or device acceptance.

## Files and provenance

| Asset | Source | Review export |
| --- | --- | --- |
| `pilot_button` | [button.ora](button.ora), 1024×256; [build_materials.py](build_materials.py) parametric construction | [turquoise primary](../exports/button_primary_normal.png), [navy secondary](../exports/button_secondary_normal.png), each 512×128 RGBA |
| Painted part of `pilot_spark_tile` | [spark_tile.ora](../spark_tile/spark_tile.ora), 512×512; same construction source | [spark_tile.png](../exports/spark_tile.png), 256×256 RGBA |

Original paint was produced with the built-in `image_gen.imagegen` tool from text prompts. Exact prompts, raw output bytes, original generator paths, dimensions, SHA-256 hashes and available invocation fields are retained in [turquoise metadata](raw/turquoise_material_r001.metadata.json) and [navy metadata](../spark_tile/raw/navy_material_r001.metadata.json). Both retained PNGs match their original generator output byte for byte. Model/version was not returned and is **unknown**. Approved Home/Combat/Map/Menu images were visually inspected for direction; none was sampled or cropped into a material. No external stock package or font licence was acquired by this material task. These records do not imply shipping rights clearance or owner approval.

## Actual editing structure

The tile ORA has **five unique, nonempty full-canvas layers**: dark outer silhouette, navy painted material, gold trim, angular corner light/shadow facets and dark inner bevel. The button ORA has **14 unique, nonempty full-canvas layers**: dark silhouette; independent turquoise and navy paint alternatives; gold trim; corner facets; inner bevel; turquoise and navy inner rims; and six independent state overlays. The turquoise normal construction is visible by default; navy alternatives and state overlays are hidden. Toggle the two material/rim alternatives together. Only meaningful alternate layers overlap; no flattened composite is duplicated and relabelled to simulate source editability.

The generated swatches contain flattened brushwork. Individual generated brush strokes are not separable, but the paint, masks, outline, trim, bevel and state resources are independently editable. The ORA's geometry is rasterized; [build_materials.py](build_materials.py) retains precise parametric construction and [overlays/](overlays/) retains editable state SVGs. Layer PNGs are also available in `layers/`. There is no separate painting-application native original because these masters were assembled from original generated paint and editable geometry.

No labels, values, circuit paths, Spark glyph, temporary marker or input hit areas are baked into these textures. The glyph/ports/tile-state source is delivered separately in `spark_tile/`.

## Slices, states and use

Button slice borders are **24 export pixels left/right, 20 top/bottom**. Tile borders are **16 export pixels on all sides**. Nominal texture-to-logical scale is 0.5: button caps use 12/10 logical pixels; tile caps use 8. Standard button live-content padding is 16/10 logical pixels, with 8/6 compact padding for 66×50 controls. Hit bounds remain the complete control rectangle.

The two normal base textures share `overlays/{pressed,focused,selected,disabled,invalid,unavailable}.{svg,png}`. Additional duplicate full button exports are intentionally omitted. `render_button(size, variant, states)` builds any combination; `responsive_overlay_svg(size, state)` and `responsive_overlay(size, state)` produce fixed-size geometry cues at the requested logical size. **Do not nine-slice/stretch marker shapes.** PNG overlays are nominal 512×128 review copies; the editable geometry must be generated for the target control in production. `state_operations` is the canonical shape recipe. See [material_metadata.json](material_metadata.json).

Pressed uses a darker inset and a separate live-label offset of (0,1) logical pixels; the control never moves. Focus is an additional cream dashed edge. Selection has an inset edge and check. Disabled has a muted fill/trim and minus. Invalid has a broken warm border and cross plus a required live explanation. Unavailable has an information circle and corner brackets, retains live name/count, and remains inspectable. Focus coexists with selection or unavailable. Hover can reuse focus; it is not essential.

The reference helper returns pixels/SVG only. It does not change game input semantics, include live text, or create Godot Theme resources. RC-013/RC-016 translate these recipes into the runtime theme and verify interaction semantics.

## Evidence and findings

| Criterion | Result | Evidence / finding |
| --- | --- | --- |
| Shared style | **Revise — owner rejected fidelity** | [color study](material-review.png) has thin regular trim and conspicuous cracked slabs. Approved references require substantial sculpted gold bevels, calmer stone, amber Spark identity and a pointed turquoise Cast silhouette. The prior compatibility assessment is withdrawn |
| Source editability | **Pass, with disclosed brushwork limit** | [validation.json](validation.json): 14 button / 5 tile unique nonempty layers, correct canvases; recomposited visible layers exactly match ORA merged image. |
| Nine-slice geometry | **Pass** | [study](material-review.png): 66×50, 180×58, 340×64, 580×92 buttons; 137×137, 72×72 and 142×92 cells/cards. Fixed cap pixel equality verified, no corner stretch. |
| States / combined states | **Pass — desktop visual** | [color](material-review.png) and [grayscale](material-review-grayscale.png): pressed, focused, selected, disabled, invalid, unavailable; focus+selected and focus+unavailable preserve shape cues. |
| Alpha / export format | **Pass — desktop visual** | [alpha backgrounds](material-alpha.png): clean corners on light gray, navy, checkerboard and turquoise. PNG dimension/mode/sRGB profile checks pass; straight RGBA8. |
| Text / input at actual scale | **Partial** | Sample labels stay separate and fit shown controls. QA helper uses local Segoe UI solely for review annotation; this is not a supplied or cleared font. Full typography and layout evidence belongs to the main pilot package. |
| Runtime import, input, device | **Not tested** | No game resources, scenes, export presets or runtime controls changed. These remain RC-013/RC-016 and later device work. |

`validate_materials.py` generates the evidence and [validation.json](validation.json). It checks actual source/export files, not generation descriptions. A compositing defect in the initial disabled overlay was corrected before the final review; the saved overlay now applies the muted fill and dark inset in separate alpha-composited steps.

Base decoded RGBA8 memory is **786,432 bytes (0.75 MiB)**: two 512×128 button bases plus one 256×256 tile. The six optional 512×128 shared overlay PNGs add **1,572,864 bytes (1.5 MiB)**; all nine review textures total **2,359,296 bytes (2.25 MiB)** without mipmaps. Procedural vector state rendering can omit those overlay textures in production. The 14×1024×256 and 5×512×512 source layer pixels occupy **19 MiB decoded**, excluding raw paint and thumbnails; they remain outside builds. Estimates are dimensions × four bytes, never compressed file size.

Do not treat r001's construction or slice defaults as visually accepted. Revise against the existing reference, including responsive pointed Cast geometry if fixed raster caps cannot preserve its silhouette. Then verify production-theme translation, imports and device behavior in their owning tasks.
