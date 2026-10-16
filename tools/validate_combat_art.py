"""Audit RC-016 resource contracts without rebuilding art or touching Git.

Checks current source/import references and a separately captured preservation
baseline. Texture totals are dimension estimates, not measured residency or
device performance. Actual rendered layout and gameplay are tested separately.
"""

import argparse
import hashlib
import json
import re
import struct
import xml.etree.ElementTree as ET
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RETIREMENT_LEDGER = "output/qa/resource-cleanup-2026-10-16/deletion-manifest.json"
RETIRED_UI = {"assets/ui/frames/pile.png"} | {
    f"assets/ui/states/{name}.svg" for name in
    ("eligible", "focused", "invalid", "powered", "protected", "selected", "unavailable", "upgrade")
}
RETIRABLE_RESOURCES = RETIRED_UI | {name + ".import" for name in RETIRED_UI} | {
    "source-assets/characters/shadeling/reference/generated-neutral.png"
}


def audit(baseline_path):
    errors = []
    counts = Counter()

    def check(ok, message, family):
        counts[family] += 1
        if not ok:
            errors.append(message)

    def read(path):
        return path.read_text(encoding="utf-8-sig")

    def digest(path):
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def relative(path):
        return path.relative_to(ROOT).as_posix()

    baseline = json.loads(read(baseline_path))
    ledger_path = ROOT / RETIREMENT_LEDGER
    ledger = json.loads(read(ledger_path)) if ledger_path.is_file() else {}
    retired = {row["path"]: row for row in ledger.get("removed", [])}

    def retired_exactly(name, expected):
        row = retired.get(name, {})
        return (name in RETIRABLE_RESOURCES and ledger.get("status") == "completed"
                and ledger.get("authorization") == "Please remove all unused resources."
                and row.get("sha256") == expected and bool(row.get("reason"))
                and not (ROOT / name).exists())

    amendment_path = ROOT / "source-assets/ui/combat/reference/authorized-resource-changes.json"
    amendments = json.loads(read(amendment_path))["files"] if amendment_path.is_file() else {}
    preservation = {"baseline": relative(baseline_path), "unchanged": 0, "changed": [], "authorized_changes": [], "retired": [], "missing": []}
    for name, expected in baseline["files"].items():
        path = ROOT / name
        if not path.is_file():
            authorized = retired_exactly(name, expected)
            preservation["retired" if authorized else "missing"].append(name)
            check(authorized, "Protected file missing without exact authorized retirement: " + name, "preservation")
        elif digest(path) != expected:
            amendment = amendments.get(name, {})
            authorized = amendment.get("baseline_sha256") == expected and amendment.get("current_sha256") == digest(path)
            preservation["authorized_changes" if authorized else "changed"].append(name)
            check(authorized, "Protected file changed without a matching owner-directed amendment: " + name, "preservation")
        else:
            preservation["unchanged"] += 1
            check(True, name, "preservation")

    # Count every resource URI once, even when its pixels equal another export.
    # All glyphs/full UI exports intentionally form a conservative family bound;
    # this includes inactive variants, the wordmark and Map-only state vectors.
    groups = {
        "crypt": sorted((ROOT / "assets/environments/crypt").glob("*.png")),
        "shadeling_active_neutral": [ROOT / "assets/enemies/shadeling/neutral.png"],
        "shadeling_optional_other_poses": [ROOT / f"assets/enemies/shadeling/{name}.png" for name in ("attack", "hit")],
        "reference_character": sorted((ROOT / "assets/enemies/shadeling/reference").glob("*.png")),
        "reference_crypt": sorted((ROOT / "assets/environments/crypt/reference").glob("*.png")),
        "core_icons_full_pack": sorted((ROOT / "assets/icons").rglob("*.svg")),
        "ui_full_pack": sorted(path for path in (ROOT / "assets/ui").rglob("*") if path.suffix in (".png", ".svg") and path.name != "app_icon.svg"),
    }
    textures = []
    for group, paths in groups.items():
        for path in paths:
            name = relative(path)
            check(path.is_file(), "Missing texture: " + name, "textures")
            if not path.is_file():
                continue
            sidecar = path.with_name(path.name + ".import")
            check(sidecar.is_file(), "Missing Godot import recipe: " + name, "imports")
            if not sidecar.is_file():
                continue
            settings = read(sidecar)
            for expected in ("compress/mode=0", "mipmaps/generate=false", "process/premult_alpha=false", "process/fix_alpha_border=true"):
                check(expected in settings, name + " import lacks " + expected, "imports")
            limit_match = re.search(r"^process/size_limit=(\d+)$", settings, re.M)
            size_limit = int(limit_match.group(1)) if limit_match else 0
            expected_limits = {"assets/environments/crypt/reference/arena.png": 960,
                               "assets/ui/combat/backdrop.png": 1024,
                               "assets/ui/combat/reference/status-frame.png": 768,
                               "assets/ui/combat/reference/icons.png": 768}
            check(size_limit == expected_limits.get(name, 0),
                  "Unexpected texture import size limit: " + name, "imports")
            cache_match = re.search(r'^path="res://([^\"]+)"$', settings, re.M)
            cache = ROOT / cache_match.group(1) if cache_match else None
            check(cache is not None and cache.is_file(), "Missing imported cache: " + name, "imports")
            if path.suffix == ".png":
                header = path.read_bytes()[:24]
                check(header[:8] == b"\x89PNG\r\n\x1a\n", "Invalid PNG: " + name, "textures")
                dimensions = list(struct.unpack(">II", header[16:24]))
                scale = 1.0
            else:
                root = ET.parse(path).getroot()
                scale_match = re.search(r"^svg/scale=([0-9.]+)$", settings, re.M)
                scale = float(scale_match.group(1)) if scale_match else 1.0
                dimensions = [round(float(root.attrib[axis]) * scale) for axis in ("width", "height")]
                check(scale == (2.0 if group == "core_icons_full_pack" else 1.0), "Unexpected SVG scale: " + name, "imports")
            source_dimensions = dimensions[:]
            if size_limit and max(dimensions) > size_limit:
                ratio = size_limit / max(dimensions)
                # Godot scales the source during import. Rounded-up estimates
                # are conservative; captures separately record actual sizes.
                dimensions = [max(1, int(axis * ratio + 0.999999)) for axis in dimensions]
            expected_size = [841, 570] if group == "crypt" else [512, 512] if group.startswith("shadeling") else None
            if expected_size:
                check(dimensions == expected_size, "Unexpected source dimensions: " + name, "textures")
            textures.append({"path": name, "group": group, "import_recipe": relative(sidecar),
                             "source_sha256": digest(path), "source_dimensions": source_dimensions,
                             "import_size_limit": size_limit, "raster_dimensions_from_source_and_import_scale": dimensions,
                             "rgba8_bytes": dimensions[0] * dimensions[1] * 4,
                             "mipmaps": False, "svg_scale": scale if path.suffix == ".svg" else None})

    resource_roots = [ROOT / "scenes/main.tscn", ROOT / "scripts/ui", ROOT / "scenes/ui/theme",
                      ROOT / "assets/ui", ROOT / "assets/fonts", ROOT / "assets/enemies/shadeling",
                      ROOT / "assets/environments/crypt"]
    files = set()
    for path in resource_roots:
        files.update([path] if path.is_file() else (item for item in path.rglob("*") if item.suffix in (".gd", ".tres", ".tscn", ".gdshader", ".gdshaderinc")))
    missing = []
    for path in sorted(files):
        content = read(path)
        for name in re.findall(r'res://([^"\s]+\.(?:tscn|tres|gdshaderinc|gdshader|gd|png|svg|ttf))"', content):
            exists = (ROOT / name).is_file()
            check(exists, relative(path) + " references missing resource " + name, "local_dependencies")
            if not exists:
                missing.append({"consumer": relative(path), "resource": name})

    slices = {}
    for name, expected in {"socket": [24, 24, 24, 24], "panel": [24, 24, 24, 24],
                           "primary": [56, 18, 56, 18], "secondary": [38, 20, 38, 20],
                           "track": [16, 8, 16, 8]}.items():
        content = read(ROOT / f"assets/ui/styles/{name}.tres")
        actual = [float(re.search(rf"texture_margin_{edge} = ([0-9.]+)", content).group(1)) for edge in ("left", "top", "right", "bottom")]
        check(actual == expected, "Changed nine-slice contract: " + name, "nine_slice")
        slices[name] = actual
    for name in ("assets/environments/crypt/environment.tscn", "assets/enemies/shadeling/character.tscn"):
        content = read(ROOT / name)
        check("texture_filter = 2" in content, "Scene must retain linear filtering: " + name, "filtering")
        check("texture_repeat = 1" in content, "Scene must disable texture repeat: " + name, "filtering")
    for name in ("scenes/ui/theme/painted_skin.gd", "scenes/ui/theme/state_layer.gd"):
        check("MOUSE_FILTER_IGNORE" in read(ROOT / name), "Decoration must ignore pointer input: " + name, "filtering")
    check("TEXTURE_FILTER_LINEAR" in read(ROOT / "scripts/ui/main.gd"), "Production screen must use linear filtering", "filtering")

    font = ROOT / "assets/fonts/ui/NotoSerif-Variable.ttf"
    reference = ROOT / "output/imagegen/approved/combat-final-v2-clean-board.png"
    atlas = ROOT / "assets/ui/combat/reference/approved-atlas.png"
    check(atlas.is_file() and digest(atlas) == digest(reference), "Reference atlas must be byte-identical to the unchanged approval", "reference_art")
    check(not list((ROOT / "assets/ui/combat/generated").glob("*.png")), "Superseded generated surfaces remain in runtime assets", "reference_art")
    archived_neutral = ROOT / "source-assets/characters/shadeling/reference/generated-neutral.png"
    check(retired_exactly(relative(archived_neutral), "a0c34e9a7082b233239fc4e7d429836be4a23992303ccce3be741b5c64219805"), "Unused generated neutral must have an exact completed retirement record and be absent", "reference_art")
    for name in sorted(RETIRED_UI):
        check(not (ROOT / name).exists() and not (ROOT / (name + ".import")).exists(),
              "Unused UI resource or import recipe was recreated: " + name, "reference_art")
    check(not (ROOT / "assets/enemies/shadeling/reference/neutral.png").exists(), "Unused generated neutral must not remain in the runtime texture family", "reference_art")
    check(font.is_file(), "Missing shared Noto font", "font")
    check((ROOT / "assets/fonts/ui/OFL.NotoSerif.txt").is_file(), "Missing bundled font licence", "font")
    check("allow_system_fallback=false" in read(font.with_name(font.name + ".import")), "System-font fallback must remain disabled", "font")
    exports = read(ROOT / "export_presets.cfg")
    exclusions = [line.split(",") for line in re.findall(r'^exclude_filter="([^"]+)"', exports, re.M)]
    for name in ("source-assets/*", "output/*", "tools/*"):
        check(len(exclusions) == 2 and all(name in entries for entries in exclusions), "Both platform presets must exclude " + name, "packaging")
    for name in ("source-assets/.gdignore", "output/.gdignore"):
        check((ROOT / name).is_file(), "Missing source/evidence import exclusion: " + name, "packaging")

    totals = {group: sum(item["rgba8_bytes"] for item in textures if item["group"] == group) for group in groups}
    one_pose = sum(value for group, value in totals.items() if group != "shadeling_optional_other_poses")
    all_poses = sum(totals.values())
    # The RC-010/015 budget includes a prospective 2 MiB VFX allowance. RC-016
    # does not load those effects; reserve them only in this comparable estimate.
    comparable = all_poses + 2 * 1048576
    check(comparable <= 32 * 1048576, "Conservative art estimate exceeds provisional 32 MiB budget", "memory")
    return {"task": "RC-016", "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "passed": not errors, "check_count": sum(counts.values()), "checks_by_family": dict(counts), "errors": errors,
            "preservation": preservation, "missing_dependencies": missing, "textures": textures,
            "nine_slice_texture_caps_left_top_right_bottom": slices,
            "memory_estimate": {"basis": "Conservative decoded RGBA8 dimensions from PNG headers, SVG scale and Godot import size limits (rounded up); distinct resource paths counted separately; runtime captures separately record actual imported sizes; no device residency measurement.",
                "group_bytes": totals, "full_icon_ui_pack_plus_crypt_one_pose_bytes": one_pose,
                "full_icon_ui_pack_plus_crypt_one_pose_mib": one_pose / 1048576,
                "all_three_poses_bytes": all_poses, "all_three_poses_mib": all_poses / 1048576,
                "all_three_poses_with_future_2mib_vfx_allowance_mib": comparable / 1048576,
                "provisional_art_budget_mib": 32,
                "exclusions": "Nine optional Shadeling part textures (9 MiB, never loaded by the whole-pose character); separate Home art; font glyph atlases; framebuffers; engine/driver/cache allocation and transient copies.",
                "overcount": "Full RC-012 and RC-013 families include inactive symbols/materials, wordmark and Map-only states. Pixel-identical panel/pile/socket files are counted separately; sharing occurs only for the same loaded Texture2D resource."},
            "limits": "Read-only resource/import-contract and hash audit. Gameplay, actual imported sizes, runtime layout, owner aesthetics, artwork rights and physical devices need their separate evidence. Existing cleanup ledger removals are not reconstructed."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", default="output/qa/rc-016/preservation-baseline.json")
    parser.add_argument("--report", default="output/qa/rc-016/resource-audit.json")
    args = parser.parse_args()
    baseline, report = [(ROOT / name).resolve() for name in (args.baseline, args.report)]
    for path in (baseline, report):
        if not path.is_relative_to(ROOT) or path.suffix != ".json":
            parser.error("Baseline and report must be JSON paths within this workspace")
    result = audit(baseline)
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": result["passed"], "checks": result["check_count"], "errors": result["errors"], "memory_estimate": result["memory_estimate"], "report": report.relative_to(ROOT).as_posix()}))
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
