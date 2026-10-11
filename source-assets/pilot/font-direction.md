# RC-011 r001 font evidence — superseded, unaccepted direction

**Owner review rejected r001's visual fidelity to the approved Combat reference.** The recommendations and fallback specimens below remain historical production evidence; they are **not an accepted style direction**. Open Sans was a layout-only fallback and did not demonstrate the required serif appearance. Do not treat its availability or successful text-fit checks as owner approval.

The isolated [r002 type and Spark revision](revisions/r002/type-geometry/README.md) now uses an **actually acquired Noto Serif2.015 font**, with its official OFL licence, exact file hash and measured variation settings retained. See the [actual r002 specimen](../../output/art/rc-011/r002/type-geometry/type-spark-specimen.png) and [font provenance](revisions/r002/type-geometry/font-provenance.json). That concrete serif revision replaces the unrendered r001 candidate comparison for review; owner aesthetic acceptance and production integration remain pending.

The historical r001 recommendation was **Noto Serif SemiBold for display and large actions**, with **Noto Sans Regular for body and inspector copy** and **Noto Sans SemiBold for compact labels and values**. It was provisional and unaccepted: Noto binaries had not been acquired for r001, and their rendered appearance was not tested there. RC-012 still owns production font packaging, embedding verification and final adoption. No runtime font is changed.

## One family and weight per role

| Role | Chosen family/weight | Proposed logical size | Pilot rendering |
| --- | --- | --- | --- |
| Display heading | Noto Serif SemiBold | 32 px | Existing engine fallback at32 |
| Primary / large action | Noto Serif SemiBold | 28 px | Existing engine fallback at28 |
| General UI / body | Noto Sans Regular | 20 px | Existing engine fallback at20 |
| Inspector body | Noto Sans Regular | 23 px | Existing engine fallback at23; scroll body |
| Inspector title | Noto Serif SemiBold | 28 px | Existing engine fallback at28 |
| Compact board / tool / hand label | Noto Sans SemiBold | 15 px;14–18 role range | Existing engine fallback; native72px board study uses compact `SPK`12 exception, with full name in inspector |
| Values / finite stock | Noto Sans SemiBold | 21 px;18 px in72px cells | Existing engine fallback; cost14 at72px, damage18, spatially separated |

The limited serif role preserves the references' storybook heading/action direction. Sans labels keep the circuit and inspector compact and legible. The custom Rune Cast wordmark remains outside this typography study. These family choices are recommendations; the actual images do **not** show Noto Serif or Noto Sans candidate files.

## Source and rights status

Official candidate source: [Noto Latin, Greek and Cyrillic](https://github.com/notofonts/latin-greek-cyrillic). Its project page identifies the fonts as OFL1.1. The [Google Fonts Noto Serif licence](https://github.com/google/fonts/blob/main/ofl/notoserif/OFL.txt) and [Noto Sans licence](https://github.com/google/fonts/blob/main/ofl/notosans/OFL.txt) were inspected and both identify the Noto Project Authors and SIL Open Font License1.1. This is online source/licence evidence, not evidence that an exact proposed binary has been downloaded, cleared or packaged. No local Noto candidate file, version or hash is claimed.

The actual specimen uses `ThemeDB.fallback_font` from the existing pinned **Godot4.7.2-stable official / ed1daf0bf001b61586d9930840f2f1394092c079**. The engine reports **Open Sans SemiBold / SemiBold**, resource class `FontFile`. [Godot's ThemeDB documentation](https://docs.godotengine.org/en/stable/classes/class_themedb.html) documents this fallback mechanism. The isolated renderer captures actual engine metrics and pixels, not an approximate system font substituted under a Noto label.

For reproducible review composition, the existing engine's unchanged fallback data was extracted to [engine-fallback-preview-only.woff2](typography/engine-fallback-preview-only.woff2),64100 bytes, SHA256 `55809808749613ed9ef9ad4f61424a14d2aa265d74369ad43403b9761aa6bac4`. Its header is `wOF2`; this is a WOFF2 file, not TTF. It is retained only under the excluded pilot source tree, with the exact [Godot4.7.2 Open Sans licence](typography/LICENSE.engine-fallback.OpenSans.txt) obtained from the [official versioned source](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/thirdparty/fonts/LICENSE.OpenSans.txt). That text identifies copyright2020 Open Sans Project Authors and OFL1.1. Licence SHA256: `01cd5ffb3a528c219a86e49a814c6c53bd8a69b9a3c305dd237074ba1c811af7`. This supports the retained review copy; it does not adopt Open Sans as a production family or settle RC-012's font package.

The earliest extraction briefly used a `.ttf` extension before its bytes were inspected. That intermediate was renamed to `.woff2`; the byte hash is unchanged. Reproduction uses the corrected path.

## Actual-size findings

[The1100×1360 type sheet](../../output/art/rc-011/pilot-type.png) is rendered at **1 output pixel per logical design pixel**, with no uniform downscaling. [Editable SVG source](typography/pilot-type.svg), [isolated Godot source](typography/render_type.gd), [measured evidence](typography/fallback-evidence.json) and [render log](typography/render.log) are retained. SVG text remains editable but can substitute fonts on another machine; the Godot PNG is the authoritative fallback specimen. The log contains a nonfatal unavailable shader-cache warning; capture returned save_error0 at the expected dimensions.

All exact required strings and numerals are present: `Spark`, `Free Spark`, `Conjure Spark`, `Cancel selection`, `Details / Pass`, `Confirm Pass / enemy acts`, `0 / 6`, `32 / 32`, and `6`/`0`/`8`/`1`.

| Measured fallback sample | Size | Actual width | Fit finding |
| --- | --- | --- | --- |
| Rotate | 15 | 48 px | Fits66×50 using compact8px horizontal padding; standard16px would not fit |
| Cancel selection | 20 | 156 px | Fits188×58 with16px horizontal padding; an initial160px sample collided and was widened |
| Details / Pass | 20 | 129 px | Fits168×64 with standard padding |
| Confirm Pass / enemy acts | 20 | 255 px | Fits312×64 without abbreviation or smaller text |
| Conjure Spark | 15 | 103 px | Fits142×92 compact hand sample |
| Temporary rune; cleared | 23 | 275 px | Fits286px inspector text width in328px panel; body scrolls and Close stays separate |

Observed at native pixels, the fallback's6/0/8/1 remain distinct;0/O and1/I are still contextual reading concerns, not a reason to rasterize values. Compact14–15px labels are legible desktop samples, not proven physical-device minimums. The pilot's72px cells use `SPK`12 instead of squeezing the full name against the cost; damage18 moves lower-left and cost14 lower-right. The full `Spark` name is retained in hand/inspector. This narrow-layout exception requires RC-012/RC-016 review and physical-device checking.

The standalone extracted subset does **not** render U+2192 reliably in the Pillow composition path, although the Godot specimen shows an arrow using the engine's broader fallback behavior. Therefore review prose uses `to`, and circuit direction uses exact vector arrowheads. RC-012 must verify letters, punctuation, digits, multiplication sign, dash/apostrophe and required accessibility strings against its actual package and fallback chain. Pictograms must be SVGs. No claim of full Unicode or translation coverage is made.

## Fallback behavior and next verification

If the chosen family or weight is absent, use the current Godot engine fallback for layout checks and label the specimen accordingly; do not silently substitute a different production family. Preserve text size, line wrapping and scrolling. Never shrink an inspector paragraph to fit a whole screen. The minimal future package is the three chosen weights, subject to RC-012's measured comparison; no full font library is proposed.

Pass: exact required specimen content, actual fallback rendering, fixed-size control fit after refinement, readable21/18px values, and recorded source/status. Not tested: Noto candidate appearance/metrics, tabular-figure support in candidate binaries, final font import/embedding, accessibility scaling and physical-device minimums. Owner style approval remains separate.

Related [glyph/rotation sheet](../../output/art/rc-011/pilot-glyphs.png): precise Spark at24/32/48/128, single-ink samples, native137/72 cells and all four exact port rotations. The sun retains a bright circular center and broad ray silhouette at24px; finest ray separations soften, but no tiny internal texture is required. Technical checks are [recorded separately](spark_tile/geometry-checks.json).
