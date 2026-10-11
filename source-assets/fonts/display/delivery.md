# RC-012 font_display — shared Noto Serif display variation

Delivered October 11, 2026, revision r001. [title.tres](../../../assets/fonts/display/title.tres) selects Noto Serif 2.015 **weight 700, width 100** for live headings and large actions. It references the single shared [runtime binary](../../../assets/fonts/ui/NotoSerif-Variable.ttf); no duplicate font is stored in this directory. This role resource does not create the Rune Cast logo or bake any labels into art.

[provenance.json](provenance.json) maps this manifest row to the shared font. The full [source, licence, fallback, import and verification record](../ui/delivery.md) belongs to `font_ui`; its retained master is the exact r002 font used by r006. The font is the practical selected direction, not a claim that the supplied reference's unknown lettering is Noto Serif.

The resource uses tested Godot `"weight"`/`"width"` variation keys and zero synthetic emboldening. If this resource is unavailable during theme development, fall back to [the bundled label variation](../../../assets/fonts/ui/labels.tres) and record that substitution. Keep the shared binary and [OFL licence](../../../assets/fonts/ui/OFL.NotoSerif.txt) in the shipped package. Unsupported-script font fallback must be explicit and licensed.

The production package and actual Godot resource checks are supplied by RC-012. RC-013 owns role-size/theme assembly; RC-016/RC-042 own full screen integration and the [usage guide](../../../docs/core-symbols-and-typography.md) defines placement. Device and owner acceptance of reconstructed assets are not inferred from this delivery.
