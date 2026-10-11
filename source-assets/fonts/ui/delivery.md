# RC-012 font_ui — Noto Serif shared font package

Delivered October 11, 2026, revision r001. The selected practical family is **Noto Serif 2.015**, reused from the retained r002 font acquisition and the r006 pilot. This does not identify the unknown font in the supplied approved artwork. The font assets remain separate from the Rune Cast logo and from the game's currently installed theme.

The unmodified source binary remains at [the retained r002 master](../../pilot/revisions/r002/type-geometry/fonts/NotoSerif-Variable.ttf). The single runtime copy is [assets/fonts/ui/NotoSerif-Variable.ttf](../../../assets/fonts/ui/NotoSerif-Variable.ttf). It is 1,887,192 bytes, SHA-256 `4d8e6761424656867019081a1a01336f3cb086982682698714054fc33f782713`. No static instance, subsetting, outline conversion or new font acquisition was necessary. `font_display` refers to the same binary.

| Role | Runtime resource | Settings |
| --- | --- | --- |
| Ordinary labels, values, card names/types/effects, forecast, piles, navigation, BEGIN/END | [labels.tres](../../../assets/fonts/ui/labels.tres) | Weight 600, width 100; tabular figures enabled |
| Location | [location.tres](../../../assets/fonts/ui/location.tres) | Weight 500, width 100 |
| Titles and large actions | [title.tres](../../../assets/fonts/display/title.tres) | Weight 700, width 100 |

These resources contain no fixed font sizes or baked labels. RC-013 will bind them to role sizes and outlined text treatments; RC-016 and RC-042 own scene integration. Keep all ordinary text live. Only BEGIN and END belong inside board cells. Free Spark identity, values and temporary duration stay in cards/details; the clean board does not acquire labels, TEMP or costs.

## Provenance and licence

[provenance.json](provenance.json) records fresh inspection of the actual sfnt name, axis, cmap and OpenType feature tables. [retained-r002-provenance.json](retained-r002-provenance.json), copied unchanged from r002, records the original acquisition URLs. [METADATA.pb](METADATA.pb) is the unchanged acquired Google Fonts metadata. Its source repository is `notofonts/latin-greek-cyrillic`, commit `c4a321e123e4d4ff315f57f4e0adf294fe3a95be`, release `NotoSerif-v2.015`. These are retained provenance records; RC-012 did not re-download or invent new acquisition metadata.

The font's embedded name table and [exact acquired OFL text](OFL.NotoSerif.txt) both identify the SIL Open Font License 1.1. Copyright 2022 The Noto Project Authors. The binary, copyright notice and licence are redistributed together in [the runtime package](../../../assets/fonts/). [ATTRIBUTION.txt](../../../assets/fonts/ATTRIBUTION.txt) identifies that dependency and its unchanged reuse. The runtime licence must remain included in distribution; the source-tree copy is not a substitute for shipping it.

## Import and font fallback

[godot-font-import.cfg](godot-font-import.cfg) preserves the actual Godot 4.7.2 import profile also shipped as the binary's `.import` sidecar: grayscale antialiasing, automatic hinting/subpixel selection, no mipmaps, no MSDF, no embedded bitmap glyphs, compression enabled, automatic oversampling. **System-font fallback is disabled.** This is important for reproducibility: unsupported text must not silently become a different OS font.

Godot's FontVariation uses `"weight"` and `"width"` keys for this binary. Although `"wght"` and `"wdth"` are the correct OpenType tags, raw tag strings in the tested Godot 4.7.2 resource silently produced default-weight RIDs. The delivered resources use the tested engine names. Tabular figures use the numeric OpenType tag `1953396077` (`tnum`). No faux emboldening is applied.

All English ASCII characters, UI samples, smart quotes, ellipsis, en/em/minus dashes, multiplication/division signs and middle dot pass actual cmap and Godot `has_char` checks. Numerals use tabular advances. The canonical family is intentionally the fallback for all current roles: if a display-role resource is unavailable during theme development, use `ui/labels.tres` and log that substitution. A missing shared binary is a packaging failure. Do not silently accept a default sans font.

For future localization, preflight each complete string with the actual resource's `has_char`; bring in and license an explicit serif fallback only for uncovered scripts, then rerun measurements and captures. A consciously equivalent punctuation normalization is possible in the text/content layer but is not implemented by this font package. Arrows, checks, hearts, lightning and game pictograms use the SVG library rather than uncertain Unicode substitutes. This policy supports the current English scope; it does not claim universal-script coverage.

## Verification and reproduction

Run `python tools/prepare_core_fonts.py` using the repository's available Python runtime. The script reads the retained source, verifies expected font/licence hashes, parses the actual sfnt tables without extra packages, writes the single runtime copy and three variations, and records [font-validation.json](../../../output/qa/rc-012/font-validation.json). It preserves all retained pilot files. The font provides a weight axis from 100 to 900, width from 62.5 to 100, and 2,965 encoded Unicode codepoints.

[The Godot probe](../../../output/qa/rc-012/font-godot-probe.json) loads the imported binary and the three resources, reads actual render RID coordinates, checks required strings and measures all ten numerals. It passed with **Noto Serif**, weights **500/600/700**, width **100**, no missing required characters, and no system fallback. At 24 px, the measured font height is 34 px (26 px ascent, 8 px descent): size Label/Control bounds from actual line metrics rather than font-size numbers alone. Equal numeral advances are confirmed within each role.

The isolated probe's source is [probe.gd](../../../output/qa/rc-012/font-probe/probe.gd). A repeat uses `Godot --headless --path output/qa/rc-012/font-probe --script res://probe.gd --quit-after 10`. Its headless font resource checks supplement the rendered RC-012 preview; they are not a visual/device result. [The usage guide](../../../docs/core-symbols-and-typography.md) and [verification record](../../../docs/verification.md) identify the actual rendered import sheets and responsive-layout checks.

The TTF costs approximately 1.80 MiB on disk before package compression. Runtime glyph-atlas memory varies with the rendered characters, sizes, outline widths and viewport scale; no fixed decoded-texture budget is claimed from the font file size. No main-game theme, runtime/core/content behavior, normal launch or gameplay semantics were changed by this font delivery. Device verification remains later work.
