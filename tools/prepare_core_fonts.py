"""Build and verify RC-012's unchanged retained Noto Serif package (stdlib only).

Godot import/render evidence is recorded separately by the isolated asset preview.
This utility never modifies the retained RC-011 source or the main game.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import struct

ROOT = Path(__file__).resolve().parents[1]
RETAINED = ROOT / "source-assets/pilot/revisions/r002/type-geometry"
RUNTIME = ROOT / "assets/fonts"
SOURCE = ROOT / "source-assets/fonts"
QA = ROOT / "output/qa/rc-012"
FONT_NAME = "NotoSerif-Variable.ttf"
EXPECTED_FONT = "4d8e6761424656867019081a1a01336f3cb086982682698714054fc33f782713"
EXPECTED_OFL = "cee9892f9f0cc8fe882c9e9537ee6a89621d86ee7ceaf70b02e2b2b1c25c061a"
ROLE_WEIGHTS = {"ui/labels": 600, "ui/location": 500, "display/title": 700}
SAMPLES = {
    "ascii": "".join(chr(n) for n in range(32, 127)),
    "punctuation": "‘’“”…–—−×÷·:;!?()[]{}/+%&@#=",
    "display": "CAST Rune Cast Resume Continue New Run Options Shop Quit",
    "location": "Floor 3 · Ashen Crypt",
    "board_endpoints": "BEGIN END",
    "controls": "Straight Corner Split Join Remove Rotate Menu Map Guide Sound Sound off",
    "cards": "Spark Free Spark Shield Focus Conjure Spark RUNE TECHNIQUE Add 6 damage. Add 5 shield. Draw 2 cards. Expires after this turn.",
    "external_values": "0/6 32/32 0 6 8 1 0123456789 12 damage 0 shield Cost 1 Incoming: 8 Draw 8 Discard 5",
    "status": "Conjure Spark created a free Spark. Cast ends turn. Unavailable. Circuit incomplete.",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def write_json(path: Path, obj: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def inspect_sfnt(path: Path) -> dict:
    data = path.read_bytes()
    u16 = lambda pos: struct.unpack_from(">H", data, pos)[0]
    i16 = lambda pos: struct.unpack_from(">h", data, pos)[0]
    u32 = lambda pos: struct.unpack_from(">I", data, pos)[0]
    fixed = lambda pos: struct.unpack_from(">i", data, pos)[0] / 65536
    tables = {}
    for index in range(u16(4)):
        pos = 12 + index * 16
        tag = data[pos:pos + 4].decode("ascii")
        tables[tag] = (u32(pos + 8), u32(pos + 12))

    # OpenType name table: actual embedded identification and licence strings.
    start = tables["name"][0]
    count, string_start = u16(start + 2), start + u16(start + 4)
    names: dict[str, list[str]] = {}
    for index in range(count):
        pos = start + 6 + index * 12
        platform, encoding, language, name_id, length, offset = struct.unpack_from(">6H", data, pos)
        raw = data[string_start + offset:string_start + offset + length]
        value = raw.decode("utf-16-be" if platform in (0, 3) else "mac_roman", errors="replace")
        values = names.setdefault(str(name_id), [])
        if value not in values:
            values.append(value)

    start = tables["fvar"][0]
    axis_start, axis_count, axis_size = u16(start + 4), u16(start + 8), u16(start + 10)
    axes = []
    for index in range(axis_count):
        pos = start + axis_start + index * axis_size
        axes.append({"tag": data[pos:pos + 4].decode("ascii"), "minimum": fixed(pos + 4),
                     "default": fixed(pos + 8), "maximum": fixed(pos + 12)})

    # Union the Unicode cmap subtables; format 4 and 12 are present in this font.
    cmap: dict[int, int] = {}
    start = tables["cmap"][0]
    formats = set()
    for index in range(u16(start + 2)):
        pos = start + 4 + index * 8
        platform, encoding, offset = struct.unpack_from(">HHI", data, pos)
        if not (platform == 0 or (platform == 3 and encoding in (1, 10))):
            continue
        sub = start + offset
        fmt = u16(sub)
        formats.add(fmt)
        if fmt == 12:
            for group in range(u32(sub + 12)):
                first, last, glyph_start = struct.unpack_from(">III", data, sub + 16 + group * 12)
                for codepoint in range(first, last + 1):
                    glyph = glyph_start + codepoint - first
                    if glyph:
                        cmap[codepoint] = glyph
        elif fmt == 4:
            segments = u16(sub + 6) // 2
            end_start = sub + 14
            begin_start = end_start + segments * 2 + 2
            delta_start = begin_start + segments * 2
            range_start = delta_start + segments * 2
            for segment in range(segments):
                end, first = u16(end_start + segment * 2), u16(begin_start + segment * 2)
                delta, roffset = i16(delta_start + segment * 2), u16(range_start + segment * 2)
                for codepoint in range(first, end + 1):
                    if codepoint == 0xffff:
                        continue
                    if roffset:
                        address = range_start + segment * 2 + roffset + (codepoint - first) * 2
                        glyph = u16(address)
                        glyph = (glyph + delta) & 0xffff if glyph else 0
                    else:
                        glyph = (codepoint + delta) & 0xffff
                    if glyph:
                        cmap[codepoint] = glyph
        else:
            raise ValueError(f"Unexpected Unicode cmap format {fmt}; update parser explicitly")

    features = {}
    for tag in ("GSUB", "GPOS"):
        start = tables[tag][0]
        feature_start = start + u16(start + 6)
        features[tag] = sorted({data[feature_start + 2 + i * 6:feature_start + 6 + i * 6].decode("ascii")
                                for i in range(u16(feature_start))})
    head, hhea, hmtx = tables["head"][0], tables["hhea"][0], tables["hmtx"][0]
    metric_count = u16(hhea + 34)
    digit_advances = {str(d): u16(hmtx + min(cmap[ord(str(d))], metric_count - 1) * 4) for d in range(10)}
    return {"names": {key: names[key] for key in ("0", "1", "2", "3", "4", "5", "6", "13", "14")},
            "axes": axes, "unicode_cmap_formats": sorted(formats), "unicode_codepoint_count": len(cmap),
            "opentype_features": features, "units_per_em": u16(head + 18),
            "default_digit_advances": digit_advances,
            "coverage": {key: {"characters": len(set(value)), "missing": sorted(set(c for c in value if ord(c) not in cmap))}
                         for key, value in SAMPLES.items()},
            "non_ui_symbols": {f"U+{ord(c):04X}": {"character": c, "covered": ord(c) in cmap}
                               for c in "→←↑↓✓✕∞⚡♥"}}


def main() -> None:
    original = RETAINED / "fonts" / FONT_NAME
    ofl = RETAINED / "fonts/OFL.NotoSerif.txt"
    assert sha(original) == EXPECTED_FONT, "Retained font changed"
    assert sha(ofl) == EXPECTED_OFL, "Retained licence changed"
    sfnt = inspect_sfnt(original)
    assert sfnt["names"]["5"] == ["Version 2.015"]
    assert not any(item["missing"] for item in sfnt["coverage"].values())
    assert {a["tag"]: (a["minimum"], a["maximum"]) for a in sfnt["axes"]} == {"wght": (100, 900), "wdth": (62.5, 100)}
    assert "tnum" in sfnt["opentype_features"]["GSUB"]
    for subdir in ("ui", "display"):
        (RUNTIME / subdir).mkdir(parents=True, exist_ok=True)
        (SOURCE / subdir).mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    target = RUNTIME / "ui" / FONT_NAME
    shutil.copyfile(original, target)
    shutil.copyfile(ofl, RUNTIME / "ui/OFL.NotoSerif.txt")
    shutil.copyfile(ofl, SOURCE / "ui/OFL.NotoSerif.txt")
    shutil.copyfile(SOURCE / "ui/godot-font-import.cfg", RUNTIME / "ui/NotoSerif-Variable.ttf.import")
    # Keep the existing exact source font in r002; do not duplicate a second master.
    shutil.copyfile(RETAINED / "fonts/METADATA.pb", SOURCE / "ui/METADATA.pb")
    shutil.copyfile(RETAINED / "font-provenance.json", SOURCE / "ui/retained-r002-provenance.json")
    for role, weight in ROLE_WEIGHTS.items():
        # Godot 4.7's FontVariation resolves named axes via "weight"/"width".
        # Raw "wght"/"wdth" serialize but are silently ignored by its RID cache.
        # Numeric OpenType feature tags avoid name-alias differences for tnum.
        features = '\nopentype_features = {\n1953396077: 1\n}' if role == "ui/labels" else ""
        content = f'''[gd_resource type="FontVariation" load_steps=2 format=3]

[ext_resource type="FontFile" path="res://assets/fonts/ui/{FONT_NAME}" id="1_font"]

[resource]
resource_name = "Noto Serif {weight} width 100"
base_font = ExtResource("1_font")
variation_opentype = {{
"width": 100.0,
"weight": {weight}.0
}}{features}
'''
        (RUNTIME / f"{role}.tres").write_text(content, encoding="utf-8")
    attribution = """Noto Serif 2.015 variable font
Copyright 2022 The Noto Project Authors (https://github.com/notofonts/latin-greek-cyrillic)
Licensed under the SIL Open Font License, Version 1.1.
The exact licence accompanies the binary in ui/OFL.NotoSerif.txt.

Shared binary: ui/NotoSerif-Variable.ttf
Original font is redistributed byte-for-byte; no conversion or subsetting.
FontVariation resources only choose existing width/weight axes.
The practical selected family is not an identification of the reference image's unknown font.
"""
    (RUNTIME / "ATTRIBUTION.txt").write_text(attribution, encoding="utf-8")
    base_record = {
        "task": "RC-012", "revision": "r001", "date": "2026-10-11",
        "family": "Noto Serif", "version": "2.015", "licence": "SIL Open Font License 1.1",
        "copyright": sfnt["names"]["0"][0],
        "retained_binary": rel(original), "runtime_binary": rel(target),
        "font_sha256": sha(target), "font_bytes": target.stat().st_size,
        "licence_file": rel(RUNTIME / "ui/OFL.NotoSerif.txt"), "licence_sha256": sha(ofl),
        "original_acquisition_record": rel(RETAINED / "font-provenance.json"),
        "source_metadata": rel(SOURCE / "ui/METADATA.pb"),
        "upstream_repository": "https://github.com/notofonts/latin-greek-cyrillic",
        "upstream_commit_from_retained_metadata": "c4a321e123e4d4ff315f57f4e0adf294fe3a95be",
        "upstream_archive_from_retained_metadata": "https://github.com/notofonts/latin-greek-cyrillic/releases/download/NotoSerif-v2.015/NotoSerif-v2.015.zip",
        "acquisition": "Reused exact retained r002 acquisition; no new download and no claim of fresh upstream verification.",
        "transformation": "Byte-identical runtime copy. No subset, format conversion, static instance or renamed font family.",
        "role_settings": {role: {"resource": f"assets/fonts/{role}.tres", "weight": weight,
                                 "width": 100, "features": {"tnum": 1} if role == "ui/labels" else {}}
                          for role, weight in ROLE_WEIGHTS.items()},
        "fallback_strategy": {
            "system_fallback": False,
            "display_resource_unavailable": "Use the bundled ui/labels.tres resource and log the missing display resource; retain serif.",
            "required_font_binary_unavailable": "Fail development import/package validation; do not ship an OS-dependent replacement.",
            "unexpected_unicode": "Check has_char for each live/localized string before release. Normalize equivalent punctuation only deliberately; use SVG for game pictograms. Unsupported scripts require an explicitly bundled and licensed matching serif fallback and fresh checks.",
            "optional_symbols": "Arrows/checks/hearts/lightning are art from the editable SVG library, not requirements placed on font fallback.",
        },
        "godot_axis_keys": {"wght": "weight", "wdth": "width", "tnum": 1953396077},
        "font_import_policy": {"antialiasing": "grayscale", "hinting": "auto", "subpixel_positioning": "auto",
                               "generate_mipmaps": False, "multichannel_signed_distance_field": False,
                               "allow_system_fallback": False, "oversampling": 0.0},
        "inspection": sfnt,
        "reference_identity": "Practical selected direction from r006; unknown supplied reference font not identified.",
        "integration_status": "Standalone production assets only. No main-game theme or gameplay changes.",
    }
    write_json(SOURCE / "ui/provenance.json", {"asset_id": "font_ui", **base_record})
    write_json(SOURCE / "display/provenance.json", {
        "asset_id": "font_display", "task": "RC-012", "revision": "r001", "family": "Noto Serif", "version": "2.015",
        "shared_provenance": "source-assets/fonts/ui/provenance.json", "runtime_binary": rel(target),
        "font_sha256": sha(target), "resource": "assets/fonts/display/title.tres", "weight": 700, "width": 100,
        "licence_file": "assets/fonts/ui/OFL.NotoSerif.txt", "fallback": "assets/fonts/ui/labels.tres",
        "duplicate_binary": False,
    })
    write_json(QA / "font-validation.json", {"task": "RC-012", "font_package_valid": True,
        "retained_font_preserved": sha(original) == EXPECTED_FONT, "retained_licence_preserved": sha(ofl) == EXPECTED_OFL,
        "shared_runtime_binary_count": len(list(RUNTIME.rglob("*.ttf"))) + len(list(RUNTIME.rglob("*.otf"))),
        "binary_byte_identical": original.read_bytes() == target.read_bytes(), "font": base_record,
        "runtime_files": {rel(p): {"sha256": sha(p), "bytes": p.stat().st_size} for p in sorted(RUNTIME.rglob("*")) if p.is_file() and p.suffix != ".import"},
        "godot_render_result": "See separate isolated Godot preview report; SFNT checks alone do not establish rendered readiness."})
    print(json.dumps({"font": rel(target), "version": sfnt["names"]["5"], "sha256": sha(target),
                      "axes": sfnt["axes"], "coverage": sfnt["coverage"], "report": rel(QA / "font-validation.json")}, indent=2))


if __name__ == "__main__":
    main()
