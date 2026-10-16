# Core symbols and typography — RC-012

October 11, 2026. This production library follows the [approved clean-board Combat reference](gameplay-visual-contract.md) and [r006 editable pilot](../source-assets/pilot/revisions/r006/delivery.md), with the retained r004 painted materials and r002 font provenance preserved. The supplied reference is owner-approved; these reconstructed production components are reference-guided and are not claimed pixel-identical or separately owner-approved.

**RC-012 complete: all eight scoped manifest records are runtime-ready.** Actual isolated Godot imports, font variations and nine rendered preview sheets pass. Final import/render evidence and readiness are recorded in [verification](verification.md#october-11-2026--rc-012-core-symbols-and-typography), separately from integration and device acceptance. The October 13 RC-016A migration uses these icons in production alongside the undirected evaluator and revised controls. [RC-016](rc-016-integration.md) now consumes the same resources throughout playable painted Combat, including live stock tools, Draw/Discard, forecast/Cast, top Pause and navigation. Source glyphs and fonts are unchanged; integration evidence and physical-device acceptance remain separate from the original isolated results.

## Source and export map

All 24 glyphs are plain editable SVG, with no font dependency, embedded raster image or external linked art. Stable manifest IDs own bounded packs; no per-rotation or per-state duplicate geometry is needed. [Source delivery](../source-assets/icons/delivery.md), [exact file/geometry/provenance metadata](../source-assets/icons/core_symbols.json) and [focused source report](../output/qa/rc-012/symbol_source_validation.json) are the authoritative per-file records.

| Asset ID | Editable source | Runtime destination and exact members |
| --- | --- | --- |
| `circuit_geometry` | [Circuit masters](../source-assets/icons/circuit/) | [Circuit exports](../assets/icons/circuit/): `begin.svg`, `end.svg`, `straight.svg`, `corner.svg`, `split.svg`, `join.svg` |
| `rune_symbols` | [Core rune masters](../source-assets/icons/runes/core/) | [Core rune exports](../assets/icons/runes/core/): `spark.svg`, `shield.svg`, `focus.svg`, `conjure.svg` |
| `temporary_marker` | [Hourglass master](../source-assets/icons/temporary_marker.svg) | [Hourglass export](../assets/icons/temporary_marker.svg); card/Guide/detail use only |
| `navigation_icons` | [Navigation masters](../source-assets/icons/navigation/) | [Navigation exports](../assets/icons/navigation/): `menu.svg`, `map.svg`, `guide.svg`, `sound_on.svg`, `sound_off.svg` |
| `editing_icons` | [Editing masters](../source-assets/icons/editing/) | [Editing exports](../assets/icons/editing/): `remove.svg`, `rotate.svg` only |
| `resource_icons` | [Resource masters](../source-assets/icons/resources/) | [Resource exports](../assets/icons/resources/): `health.svg`, `energy.svg`, `attack.svg`, `draw_pile.svg`, `discard_pile.svg`, `pause.svg` |
| `font_ui` | [UI font source/licence/provenance](../source-assets/fonts/ui/) | [UI font package](../assets/fonts/ui/): `NotoSerif-Variable.ttf`, `labels.tres`, `location.tres`, licence/attribution |
| `font_display` | [Display-role records](../source-assets/fonts/display/) | [Display resources](../assets/fonts/display/): `title.tres` references the one UI binary; no duplicate TTF |

Split and Join reuse the actual r006 sideways-fork and upright-trident paths with uniform normalization. The established pilot's Begin check, End diamond and rune/navigation/resource silhouettes inform precise vector construction. No new raster art or image generation was used. At 24px some Conjure/Draw-pile inner details soften; use 32/48px when that detail matters and keep live labels. The builder is [build_core_symbols.py](../tools/build_core_symbols.py); reuse does not change retained pilot files. Later rune, relic and room batches remain RC-041.

## Geometry and clean-board use

Every SVG has `viewBox="0 0 128 128"`, top-left origin, center/pivot `(64,64)`, decorative safe bounds `(16,16)` to `(112,112)`. Straight/Corner are exact connection geometry and intentionally reach the cell edges. Ports are N`(64,0)`, E`(128,64)`, S`(64,128)`, W`(0,64)`, with a 10-unit half-width clear channel. Rotate connection geometry clockwise around the center; each turn maps N→E→S→W. The Begin check and End diamond keep their upright identity while their separate ports rotate. The owner's October 15 correction applies the same separation to Split and Join: keep the sideways fork and upright trident in their original orientation while only their connection lines follow the rotated ports. The 6px grid gap belongs to the renderer, which must bridge corresponding edges without moving the ports inward.

The final SVG wire stroke is 8 normalized units with a 2-unit highlight, giving 1.5/2/3px at 24/32/48px icon sizes and 4.5/8.5625px at 72/137px cells. Actual Godot inspection prompted this stronger stroke for small toolbar sizes; exact edge coordinates are unchanged. A live drawing renderer uses the same proportional 8/128 width, with a 3px minimum when needed. Connection strokes have blunt ends and no directional arrowheads. The curved arrow in Rotate is an editing action, outside circuit connectivity.

Decorative symbols, connection segments and text are separate layers. Begin uses a single check, End a diamond. Keep BEGIN/END live and upright, repositioning the label clear of a south-facing port; these are the **only board text**. Do not add other rune names, damage/shield values, path/End totals, costs, TEMP or upgrade badges to board cells. Split/Join silhouettes remain the approved fork/trident at every quarter-turn, with no stray connection strokes from decorative tips. The October 13 RC-016A decision defines three logical ports each: Split W/E/S and Join N/E/S before clockwise rotation. These are explicit model metadata, not inferred from the fork/trident outline. Production connections have no input/output polarity; the complete Begin-to-End graph determines branch/merge roles.

Spark and Free Spark share exactly the same board glyph. The hourglass is allowed only in detailed cards, Guide or an actual detail description, paired with live Free Spark name, zero cost and lifetime text. Shape plus text distinguishes them without colour alone. Focus and Conjure are techniques; their standalone symbols do not imply board placement.

## Controls, states and supporting information

Remove eraser and Rotate are the only circuit editing actions. There are no Flip, Undo, Inspect, Cancel selection, Details/Pass or generic Close exports. Actual dialogs keep their separate live text Close control. RC-016A uses a focusable Info button per hand card, hold-to-inspect and I/right-click shortcuts; the forecast opens circuit details, while Escape or a repeated card/tool tap clears selection. The visible Pass turn action occupies the WIRING-label position beside the connector tools and confirms the incoming attack and cleanup. It is a turn action, not another editing action. The top Pause glyph has its own `combat_pause` consumer.

Navigation remains Menu, Map, Guide and Sound. Sound off has a cross and Sound on has waves. Resource values, forecast labels, card cost/name/type/effect text and Draw/Discard labels/counts remain live. Draw/Discard are explicitly assigned to `combat_piles`, and the permanent damage/shield/cost/incoming summary above pointed turquoise Cast is `combat_forecast`. Keep the action-log line above the hand. The reference's infinity stock, BOSS label, fixed circuit and sample numbers establish no gameplay rules.

Use shared state treatments: normal retains contours; selected adds a persistent notch/check; focused adds a distinct dashed outline; disabled/unavailable combines muted rendering with an unavailable marker/reason; invalid uses a cross or broken-path cue. Keep focus visible when combined with selected or unavailable. Powered/unpowered connections need a collar/shape difference. State overlays never imply additional ports or add forbidden board text. The [tint shader](../assets/icons/symbol_tint.gdshader) shares source geometry: mode 0 colour, mode 1 grayscale preserving internal facets, mode 2 flat alpha silhouette. Mode 1 maps luminance between `monochrome_paper` and `ink`, preserving internal shapes: use black paper/cream ink on stone, and paper `#e8d5aa`/ink `#111b27` on parchment. A flat dark modulation alone collapses details on parchment. Flat silhouettes are diagnostic; the grayscale specimen is the monochrome readability check.

## Typography and licence

The font is **Noto Serif 2.015**, 1,887,192 bytes, SHA-256 `4d8e6761424656867019081a1a01336f3cb086982682698714054fc33f782713`. The runtime TTF is byte-identical to [retained r002](../source-assets/pilot/revisions/r002/type-geometry/fonts/NotoSerif-Variable.ttf): no conversion, subsetting or static instancing. [Exact OFL1.1 text](../assets/fonts/ui/OFL.NotoSerif.txt), [UI provenance](../source-assets/fonts/ui/provenance.json) and [display provenance](../source-assets/fonts/display/provenance.json) retain copyright, acquisition URLs and transformation records. RC-012 reuses that acquisition and does not claim a fresh upstream download. Noto is the selected practical serif direction, not an identification of the unknown supplied-reference font.

| Live role | Resource | Variation |
| --- | --- | --- |
| Title and large action | [title.tres](../assets/fonts/display/title.tres) | weight 700, width 100 |
| Ordinary labels, values, detailed card text, counters | [labels.tres](../assets/fonts/ui/labels.tres) | weight 600, width 100; tabular figures enabled |
| Location label | [location.tres](../assets/fonts/ui/location.tres) | weight 500, width 100 |

The font's SFNT axis tags are `wght`/`wdth`, but Godot 4.7.2 `FontVariation.variation_opentype` uses the keys **`weight`** and **`width`**. Using raw tags there can silently leave the default variation. Labels enable `tnum` via its numeric OpenType tag 1953396077. The [actual Godot probe](../output/qa/rc-012/font-godot-probe.json) checks instantiated render RIDs and selected axes, required coverage and tabular digit advances. [Font validation](../output/qa/rc-012/font-validation.json) checks names, hashes, licence, resources and glyph repertoire.

Use cream text with a dark outline at the live Control level. RC-013 selects per-role sizes/margins based on the delivered specimens; no global theme switch was made for RC-012. All ordinary labels/values remain live; the separate logo is RC-013. English punctuation, long labels and 0/6/8/1 must fit without clipping; card descriptions may wrap and narrow layouts may scroll.

Fallback is deterministic: share the bundled Noto font across roles, and fall back from a missing display resource to bundled `labels.tres` with a diagnostic. A missing required binary fails package/import validation. System font fallback is disabled, so an unrelated local sans cannot conceal missing coverage. Unsupported future glyphs/locales require an explicitly bundled, licensed matching serif fallback and fresh coverage/layout checks. Use the SVG library for game pictograms instead of depending on Unicode icons. Font atlas memory is dynamic and excluded from texture estimates.

## Isolated Godot preview and imports

Run the [preview wrapper](../tools/preview_core_assets.ps1) from the repository root:

```powershell
.\tools\preview_core_assets.ps1
```

The [preview project](../tools/rc012_preview/project.godot) stages exact production font/icon copies under `output/qa/rc-012/preview-project`. It imports the SVGs and real TTF/resources with the pinned Godot renderer and writes actual rendered output. This is an isolated specimen project; it does not replace the main scene or claim a rebuilt whole Combat screen. The source masters stay behind `source-assets/.gdignore`; `source-assets/*` is explicitly excluded from exports. Review output is already excluded. The original RC-012 delivery left normal gameplay untouched; the later RC-016A integration is recorded separately. Both platform presets also explicitly include `assets/fonts/ATTRIBUTION.txt` and `assets/fonts/ui/OFL.NotoSerif.txt` so licences ship with exports.

SVG import scale 2 produces 256×256 textures; use lossless storage, no mipmaps, linear filtering and no repeat. 24 RGBA8 textures total **6 MiB** decoded, before engine overhead and dynamic font atlases. This is a dimensional estimate, not measured resident/device memory. The preview reports GL Compatibility on the Windows NVIDIA GeForce RTX 5070 Ti; no mobile/device claim follows. Font import and role settings are recorded in their source provenance.

| Actual-render evidence | Scope |
| --- | --- |
| [Symbols](../output/art/rc-012/symbols.png) | 24/32/48px, colour/monochrome, dark indigo/retained painted stone/parchment contexts and Sound states |
| [States and rotations](../output/art/rc-012/states-and-rotations.png), [72px rotations](../output/art/rc-012/rotations-72.png) | Applicable normal/selected/focused/disabled-unavailable/invalid treatments and all quarter-turns, 137/72px cells |
| [Action states](../output/art/rc-012/action-states.png) | Remove/Rotate and supporting actions in normal, selected, focused, disabled/unavailable and invalid treatments |
| [Typography](../output/art/rc-012/typography.png) | Actual font weights, live card and supporting labels, long labels and ambiguous numerals |
| [720×1600](../output/art/rc-012/layout-720x1600.png), [450×1000](../output/art/rc-012/layout-450x1000.png) | Isolated live layout specimens at design and desktop display scale |
| [Native360×640](../output/art/rc-012/layout-360x640.png), [native card companion](../output/art/rc-012/layout-360x640-cards.png) | Separate narrow layout, not a scaled full-screen substitute |
| [Import log](../output/qa/rc-012/godot-import.log), [render log](../output/qa/rc-012/godot-render.log), [render results](../output/qa/rc-012/godot-render-results.json) | Engine import/render resources, sizes, variation and clipping evidence |
| [Delivery validation](../output/qa/rc-012/validation-report.json), [independent visual review](../output/qa/rc-012/visual-review.json), [asset-plan validation](../output/qa/rc-012/asset-plan-validation.json) | Paths/coverage/state/licence/preservation/document checks and limits |

The [delivery audit](../tools/validate_core_assets.py) passes 939 checks: 278 protected files unchanged, 24 SVG source/export pairs, nine actual Godot sheets, 387 live text measurements and 96 imported texture rotation cases. Run `python .\tools\validate_core_assets.py` after rendering.

Godot logs include host `user://` directory, shader-cache and root-certificate-store warnings; the final import/render checks report no missing resource, SVG, font or script errors. The native 360 card companion and 72px rotation sheet were also independently inspected for clipping and endpoint identity.

The [asset-plan validator](../tools/validate_asset_plan.py) accepts a separate report destination so later tasks preserve the historical RC-010 report:

```powershell
python .\tools\validate_asset_plan.py --report output/qa/rc-012/asset-plan-validation.json
```

## Integration boundary

RC-012 owns the source/export/font/import package and isolated evidence; RC-013 supplies the reusable theme. The owner-approved RC-016A migration now defines and implements undirected connectivity, logical ports, branch/rejoin aggregation, feedback rejection, once-per-physical-piece effects/costs, visible confirmed Pass turn and revised controls/live information bindings. Its dated verification and handoff own gate status. Full RC-016 painted integration remains separate. RC-017 owns event-driven motion; RC-041 owns later icon batches; RC-050 retains final credits/rights audit. Neither reference approval nor the isolated RC-012 desktop specimens establish full integration, owner approval of reconstructed components or Android/iOS device acceptance.
