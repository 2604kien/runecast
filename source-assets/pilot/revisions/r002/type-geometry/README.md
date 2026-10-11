# r002 — reference-matching typography and Spark

The owner rejected r001's mismatch with the approved Combat image. This isolated revision supplies actual serif lettering and a larger, simpler amber sun. It does not modify r001, game assets, imports, scenes or runtime themes.

## Ready-to-use review files

- [Actual type and Spark specimen](../../../../../output/art/rc-011/r002/type-geometry/type-spark-specimen.png),1100×1230, viewed and refined at actual exported dimensions.
- [Editable specimen SVG](type-spark-specimen.svg): live text and linked editable Spark, not flattened text or a cropped reference.
- [Spark SVG](spark.svg):128×128 viewBox, essential alpha bounds16–112, separate rays/center/light groups, no text, embedded raster, filters or drawn connections.
- [Official Noto Serif variable font](fonts/NotoSerif-Variable.ttf) and [actual licence](fonts/OFL.NotoSerif.txt).
- [Provenance and font metadata](font-provenance.json), [measured strings](font-measurements.json), and [geometry contract](spark-geometry-contract.json).

## Font obtained and rendered

The exact downloaded binary reports **Noto Serif Version2.015** in its SFNT name table. It is1887192 bytes, SHA256 `4d8e6761424656867019081a1a01336f3cb086982682698714054fc33f782713`. It was obtained from the [official Google Fonts Noto Serif directory](https://github.com/google/fonts/tree/main/ofl/notoserif), together with that directory's OFL licence and metadata. The licence identifies copyright2022 Noto Project Authors and SIL Open Font License1.1; the actual text is retained with the binary. No font version or source identity is inferred from appearance.

Use **weight600 / width100** for the serif SemiBold review role. In Pillow, load the variable file and call `font.set_variation_by_axes([600,100])`; its axis order is Weight, Width. The base font name remains Regular because that is the variable font's default instance; the actual rendering selects600 explicitly. Body annotations on this comparison use400.

Recommended Combat review role sizes are36px title,48px Cast,38px large Resume/Continue,17px board label,20px card label,30px values,21px navigation and20px reading text. Render cream `#fff0ca` with a1–3px dark `#08121e` outside outline depending on size; gold headings use `#edb152`. This reproduces the reference's sturdy serif forms and contrast more closely than r001's small unoutlined fallback. Final small inspector/control font choice and device measurements remain separate verification work.

The actual file is now obtained and its licence evidence is present. This is **review-only acquisition**, not production integration or owner approval. No font library or full family was downloaded. The plain arrow U+2192 was missing from the direct Pillow rendering of this file, so specimen prose uses words; gameplay arrows remain SVG geometry. No broad Unicode coverage claim is made.

## Spark refinement and display size

The approved Combat reference shows a large bright center with16 narrow, long amber rays. The revision uses a flat yellow center, slight upper highlight,1.5-unit warm ray border and2.5-unit warm circle border. The previous8-unit navy silhouette and6-unit inner border were provisional values and made the tiny r001 symbol read as a dark gear. This is an explicit visual-review exception; the parent task owns reconciliation with the brief/spec after review.

The128-unit canvas, center64,64, safe art bounds16–112 and exact edge ports are preserved. Ports are metadata only in the glyph: N64,0; E128,64; S64,128; W0,64. Rotation0 remains W input to E output, with clockwise quarter-turns. No cost, value, rune name or circuit is baked into the symbol.

Actual raster inspections cover24,32,48,62,80 and128px canvases. At24px the center and sun silhouette remain visible while the finest ray separations soften. At62px canvas the visible sun is about46–48px wide. **Use80px canvas for approximately60px visible sun on a137px cell**, closer to the approved reference's sun-to-cell ratio. Both62 and80px cell samples are shown; the80px treatment is recommended. At72px cells, use a smaller size and a dedicated narrow layout; do not reuse the137px text positions blindly.

The `spark-*.png` files are raster inspection derivatives; the SVG is authoritative. `build_type_geometry.py` produces the editable geometry/provenance, `render_spark.cjs` rasterizes it using Sharp, and `compose_specimen.py` renders actual Noto Serif using Pillow/FreeType. SVG text may substitute on another system without the font; the delivered PNG and font-provenance record define the inspected render.

Pass: official font/actual licence acquisition, decoded name/version/hash, actual serif rendering, all requested sample strings/numerals, required Spark sizes, SVG structure and art bounds. Remaining: owner aesthetic acceptance, final linked Combat composition review, production font import/embedding and physical-device readability. No owner approval is claimed.
