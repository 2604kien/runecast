# RC-011 r002 — correction against the approved reference

**Superseded visual target:** The owner has now established the [official complete gameplay image](../../../../output/imagegen/approved/combat-final.png), with full crypt/supporting UI, undirected circuits, Remove/Rotate, piles and the info bar. [r003 delivery](../r003/delivery.md) records the exact supplied image and new scope. The r002 findings below remain history; its placeholder permission is no longer applicable to future complete previews.

October 11, 2026. The owner clarified that the rejected image was the RC-011 preview shown in this chat, not a separate RC-012 build. The approved gameplay image already fixes the visual target. No further style confirmation is requested.

**Status: concrete correction delivered; reference matching still requires work.** This revision materially corrects the character identity/scale, Spark proportions/colour, frame construction, Cast silhouette and rendered typography. It is not an exact reproduction of the full approved gameplay screen. The environment, non-Spark iconography and supporting screen decoration remain blockouts under the original pilot scope. RC-011 remains open; r001's visual pass has been withdrawn. Neither revision is an approved production baseline.

## Review output

- [720×1600 correction](../../../../output/art/rc-011/r002/pilot-720x1600.png), [450×1000](../../../../output/art/rc-011/r002/pilot-450x1000.png), [editable composition](pilot_review.svg).
- [Native360×640 board](../../../../output/art/rc-011/r002/pilot-360x640.png), [lower controls](../../../../output/art/rc-011/r002/pilot-360x640-controls.png), [inspector](../../../../output/art/rc-011/r002/pilot-360x640-inspector.png).
- [States and alpha](../../../../output/art/rc-011/r002/pilot-states.png), [grayscale states](../../../../output/art/rc-011/r002/pilot-states-monochrome.png), [actual serif/type and Spark specimen](../../../../output/art/rc-011/r002/pilot-type.png), [reference comparison](../../../../output/art/rc-011/r002/pilot-reference-comparison.png).
- [Motion GIF](../../../../output/art/rc-011/r002/pilot-motion.gif), [48-frame PNG sequence](../../../../output/art/rc-011/r002/pilot-motion-frames/), [timing](../../../../output/art/rc-011/r002/pilot-motion-timing.json), [keyframes](../../../../output/art/rc-011/r002/pilot-motion-sheet.png).

## Sources and corrections

| Asset | Exact editable sources and export | Correction |
| --- | --- | --- |
| pilot_shadeling | [7-layer1024² ORA](shadeling.ora), [masks](separation-masks.svg), [reproducible assembly](build_shadeling.py), [512²export](exports/shadeling.png), [aligned parts](exports/shadeling_parts/), [metadata](metadata.json) | New painting supplied the actual approved Combat image as an image reference. Broad stance, short angular hood, cream mask, burgundy/purple cloak planes, gold clasp/chain and squat lantern replace the elongated detailed r001 figure. Display scale0.64 yields≈231px visible height instead of166px; source/export foot anchors remain512,896/256,448 |
| pilot_spark_tile | [amber frame ORA](ui/tile_spark.ora), [empty frame ORA](ui/tile_empty.ora), [frame SVG](ui/tile_spark.svg), [Spark SVG](type-geometry/spark.svg), [monochrome](type-geometry/spark-monochrome.svg), [geometry contract](type-geometry/spark-geometry-contract.json) | Brown/amber face, broad gold bevel and long-ray yellow sun.80px glyph canvas on137px cell gives≈60px visible sun;34px canvas on72px cells. Exact128-unit port geometry retained; upright labels/values separate |
| pilot_button | [Cast ORA](ui/button_cast.ora), [primary ORA](ui/button_primary.ora), [secondary ORA](ui/button_secondary.ora), [Cast SVG](ui/button_cast.svg), [responsive builder](ui/build_ui.py), [metadata](ui/candidate-metadata.json) | Substantial gold edge planes and long hexagonal Cast ends; turquoise primary/navy secondary. Base materials, bevels and states remain separate. Standard frames retain proposed slices; Cast uses responsive geometry because24px raster caps cannot preserve long ends |
| pilot_review | [composition builder](build_review.py), [renderer](render_review.cjs), root pilot SVGs, [actual font](type-geometry/fonts/NotoSerif-Variable.ttf), [actual OFL](type-geometry/fonts/OFL.NotoSerif.txt), [font record](type-geometry/font-provenance.json) | Cream outlined Noto Serif2.015, weight600/width100, is actually rendered. r001's Open Sans fallback is no longer used to represent a matching type treatment. This does not claim the unknown exact reference typeface has been identified |

The retained [raw character](raw/shadeling.png) and [exact prompt](raw/shadeling.prompt.txt) were produced with built-in `image_gen.imagegen`, using `output/imagegen/approved/combat.png` as `referenced_image_paths`, with transparency requested. No model/version/seed was exposed. Raw/source/reference hashes and original generator path are in metadata. r001 raw material generations remain the source for the revised UI paint; [UI metadata](ui/candidate-metadata.json) records colour/contrast refinements. No approved reference pixels were used as game textures.

## Technical refinements and checks

The revised Shadeling preserves genuine full-canvas body, underlap, arm, glass backing, lantern shell, glass light and flame layers. Its neutral nonzero alpha occupies60,86–406,451; all motion alpha occupies33,83–418,461, within32–480. The lean hierarchy and reduced-motion counterpart are demonstrations only; hidden anatomy, final poses and gameplay event integration remain future work. The original allowed PNG-sequence substitute is retained, plus GIF playback.

Spark's provisional8/6dark outline was unsuitable for the reference's sun. r002 uses1.5-unit warm ray edges and2.5-unit center edges, preserving the128viewBox,16–112safe artwork bounds and exact edge ports. The selected notch moves to the bottom-right so it no longer covers the SPARK label. Begin/End contextual placeholders use closed/filled versus open/hollow silhouettes; they are not final RC-012 symbols. Cost, damage, TEMP and finite stock remain separate live-style content.

The [revision validator](validate_revision.py) passes **509 actual-artifact checks** in its [report](../../../../output/art/rc-011/r002/revision-validation.json): dimensions/RGBA/sRGB, genuine nonempty distinct ORA layers, exact recomposition, aligned part canvases, anchors, per-frame motion bounds, linked resources, editable text, font/reference/raw hashes and source exclusion. [UI file checks](ui/file-checks.json) separately check all six layered material sources. Passing these checks does not establish visual fidelity.

No gameplay suite was rerun: no runtime scene, game assets, rules/data, main controls or export presets were changed. No Git operations were performed during this correction. r001 sources/review images and previous raw evidence are preserved.

Conservative decoded candidate art is **11.625MiB** if neutral512² plus seven512²parts, three256²tile materials, three512×128button constructions, six optional512×128state rasters and ten128²SVG rasterizations are all retained:8+0.75+0.75+1.5+0.625. Equivalent duplicate review exports are counted once; source ORAs/raw paint/review sheets are excluded. A static subset with neutral, two tile faces, two button bases and Spark/TEMP is≈2.125MiB. The acquired font requires separate engine/font-atlas measurement. These are dimension-based estimates, not compressed sizes, a production loading plan or device measurements.

## Recorded review

| Criterion | Finding |
| --- | --- |
| Match approved visual identity | **Revise.** The three candidates are visibly closer; full screen appearance is still different. Broad character contour, serif treatment, amber Spark and pointed Cast now follow the reference. Remaining material/edge finishing and direct reference comparison must precede an acceptance claim |
| Actual-size readability | **Desktop inspected, device not tested.**137/72cells,80/34glyph contexts,24/32/48specimens,450preview and native narrow companions inspected. Small-cost crystal remains close to the frame and needs device review |
| Technical source/export integrity | **Pass for artifacts.**509checks above; seven meaningful actor layers, separate material/bevel sources, no baked labels or circuit in runtime-format art |
| State coverage | **Desktop construction covered.** Seven button states/focus combinations, Spark rotations, power, TEMP, selection/focus/invalid/unavailable/eligible/protected shown. Shared r001 state recipes still need final appearance review over corrected frame geometry |
| Motion/source feasibility | **Demonstrated, unintegrated.**48frames with reduced counterpart and envelope guides; constrained underlap remains a disclosed limitation |
| Owner approval / exact screen match | **Not claimed.** Existing references remain the target. No request to approve a different style |

The unresolved difference is not solved by labelling a blockout “matching.” RC-012 must not inherit the rejected appearance as an approved baseline. Full crypt, complete core icons and theme production remain assigned to RC-012–RC-015 under the current scope; their absence here is explicit rather than counted as completed screen fidelity.
