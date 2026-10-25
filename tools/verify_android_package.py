#!/usr/bin/env python3
"""Audit an actual standard Godot APK without loading documentation catalogues.

Uses Python's standard library. Imported WAV/PNG/font sources normally ship as
their .import remap and compiled resource, rather than as the original file.
The optional resource ZIP contains byte-identical APK assets for a separate
desktop Godot decoding probe; neither check establishes physical-device success.
"""

from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import sys
import zipfile


PRODUCTION_DATA = (
    "runes.json", "enemies.json", "production_boards.json",
    "production_loadouts.json", "production_rules.json", "production_encounter.json",
    "production_next_encounter.json", "production_transition_encounter.json",
    "production_wickling_encounter.json", "production_stone_sentinel_encounter.json",
    "production_chain_warden_encounter.json", "production_bell_keeper_encounter.json",
)
ATTRIBUTION = ("assets/fonts/ATTRIBUTION.txt", "assets/fonts/ui/OFL.NotoSerif.txt")
LIVE_REFERENCE = (
    "assets/ui/combat/reference/approved-atlas.png",
    "assets/ui/combat/reference/status-frame.png",
    "assets/ui/combat/reference/icons.png",
    "assets/ui/combat/reference/navigation_mask.gdshader",
    "assets/enemies/shadeling/reference/approved_actor.gdshader",
    "assets/enemies/shadeling/reference/approved_actor_mask.gdshaderinc",
    "assets/environments/crypt/reference/arena.png",
    "assets/environments/crypt/reference/visible_edges.gdshader",
)
# The app wrapper and isolated Combat are both supported runtime entry points.
# Keep these explicit as well as the discovered inventory: an incomplete source
# transfer must not silently narrow the required production payload.
APPLICATION_RUNTIME = (
    "scenes/application.tscn",
    "scenes/main.tscn",
    "scenes/ui/theme/navigation_bar.gd",
    "scenes/ui/theme/modal_panel.gd",
    "scenes/ui/theme/combat_surface.gd",
    "assets/ui/styles/modal_panel.tres",
    "scripts/ui/application_shell.gd",
    "scripts/ui/reward_viewer.gd",
    "scripts/ui/run_review.gd",
    "scripts/ui/temporary_enemy_actor.gd",
    "scripts/core/store_policy.gd",
    "scripts/ui/store_viewer.gd",
    "scripts/ui/shop_viewer.gd",
    "scripts/ui/service_viewer.gd",
    "scripts/ui/collection_viewer.gd",
    "scripts/ui/collection_data.gd",
    "scripts/core/run_state.gd",
    "scripts/core/local_save.gd",
    "scripts/core/shop_policy.gd",
    "scripts/core/service_policy.gd",
    "scripts/core/instance_effects.gd",
    "scripts/core/catalogue_policy.gd",
    "scripts/core/relic_policy.gd",
    "scripts/core/progression_state.gd",
    "scripts/core/route_state.gd",
    "scripts/core/encounter_resolver.gd",
    "scripts/ui/route_map.gd",
    "scripts/ui/route_map_canvas.gd",
    "scripts/ui/route_map_symbol.gd",
    "scripts/ui/route_map_node.gd",
    "scripts/ui/route_map_chrome.gd",
    "assets/ui/map/parchment.png",
    "assets/environments/home/home_tower.png",
    "assets/ui/wordmark.png",
)
RESOURCE_SUFFIXES = {
    ".gd", ".tscn", ".tres", ".gdshader", ".gdshaderinc", ".png", ".svg",
    ".ttf", ".otf", ".wav", ".ogg",
}
FORBIDDEN_PREFIXES = (
    "docs/", "output/", "tools/", "tests/", "source-assets/", ".tools/",
    ".local/", ".git/", ".codex/", ".agents/", "builds/", "android/",
    ".godot/editor/", "data/development/", "scripts/dev/", "export_templates/",
    "feature_profiles/", "script_templates/", "text_editor_themes/",
)
FORBIDDEN_SUFFIXES = {
    ".md", ".html", ".py", ".ps1", ".bat", ".cmd", ".ora", ".psd",
    ".kra", ".blend", ".jks", ".keystore", ".p12", ".pem", ".key",
}
FORBIDDEN_FILES = {"data/board_examples.json", "data/dev_encounter.json", "export_presets.cfg"}
REMAP_PATH = re.compile(r'^path(?:\.[^=\s]+)?\s*=\s*"res://([^"\r\n]+)"', re.MULTILINE)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def safe_name(name: str) -> bool:
    path = PurePosixPath(name)
    return bool(name) and not path.is_absolute() and ".." not in path.parts and "\\" not in name and ":" not in name


def audit(apk: Path, project: Path, expected_abis: set[str], resource_pack: Path | None) -> dict:
    report = {
        "schema": "runecast_android_package_v1",
        "checked_at_utc": datetime.now(timezone.utc).isoformat(),
        "apk": str(apk), "apk_size_bytes": apk.stat().st_size,
        "apk_sha256": sha256(apk.read_bytes()),
        "scope": "Static inspection of actual APK. Device behavior, signature, manifest identity and decoded loop properties require their separate checks.",
        "checks": [], "required_resources": [], "entries": [],
    }

    def check(ok: bool, description: str, **details: object) -> None:
        report["checks"].append({"passed": bool(ok), "description": description, **details})

    with zipfile.ZipFile(apk) as archive:
        infos = [info for info in archive.infolist() if not info.is_dir()]
        names = [info.filename for info in infos]
        duplicates = sorted(name for name, count in Counter(names).items() if count != 1)
        unsafe = sorted(name for name in names if not safe_name(name))
        check(not duplicates, "ZIP entries are unique", paths=duplicates)
        check(not unsafe, "ZIP entry paths are safe", paths=unsafe)
        check("AndroidManifest.xml" in names and "classes.dex" in names, "Archive has Android APK structure")
        corrupt = archive.testzip()
        check(corrupt is None, "All ZIP entry CRCs are valid", corrupt_entry=corrupt)
        abis = sorted({name.split("/")[1] for name in names if name.startswith("lib/") and name.endswith(".so")})
        report["architectures"] = abis
        check(set(abis) == expected_abis, "Only requested native architectures are packaged", expected=sorted(expected_abis), actual=abis)
        for abi in sorted(expected_abis):
            check(f"lib/{abi}/libgodot_android.so" in names, "Godot Android runtime exists", architecture=abi)

        # Standard unencrypted Godot Android export stores res:// under assets/.
        resources = {name[7:]: archive.read(name) for name in names if name.startswith("assets/")}
        check("project.binary" in resources, "APK contains exported Godot project settings")
        unknown_roots = sorted(name for name in resources
                               if not name.startswith(("assets/", "scenes/", "scripts/", "data/", ".godot/"))
                               and name not in {"project.binary", "_cl_", "assets.sparsepck"})
        check(not unknown_roots, "APK project payload uses only expected runtime roots", paths=unknown_roots)
        for info in sorted(infos, key=lambda value: value.filename):
            report["entries"].append({"path": info.filename, "bytes": info.file_size,
                                      "sha256": sha256(archive.read(info.filename))})
        forbidden = sorted(name for name in resources if name.startswith(FORBIDDEN_PREFIXES)
                           or name in FORBIDDEN_FILES or PurePosixPath(name).suffix.lower() in FORBIDDEN_SUFFIXES)
        check(not forbidden, "Development/source/signing material is excluded", paths=forbidden)

        # Validate every remap, including entries that are not explicitly required.
        remaps = {}
        for name, contents in sorted(resources.items()):
            if not name.endswith((".import", ".remap")):
                continue
            targets = REMAP_PATH.findall(contents.decode("utf-8", errors="strict"))
            remaps[name] = targets
            check(bool(targets) and all(target in resources and resources[target] for target in targets),
                  "Resource remap resolves to nonempty packaged data", path=name, targets=targets)

        def require(path: str, category: str, exact_source: bool = False) -> None:
            target_names = [path] if path in resources else remaps.get(path + ".remap", remaps.get(path + ".import", []))
            present = bool(target_names) and all(name in resources and resources[name] for name in target_names)
            record = {"path": path, "category": category, "packaged_paths": target_names, "present": bool(present)}
            if exact_source and present:
                same = resources[path] == (project / path).read_bytes()
                record["matches_workspace"] = same
                check(same, "Packaged plain-text data matches workspace", path=path)
            if path + ".import" in resources and present:
                # Binary imports are platform-dependent for textures. Audio and
                # font imports are invariant for this Compatibility export.
                if Path(path).suffix.lower() in {".wav", ".ogg", ".ttf", ".otf"}:
                    matches = all((project / name).is_file() and resources[name] == (project / name).read_bytes() for name in target_names)
                    record["matches_workspace_import"] = matches
                    check(matches, "Packaged audio/font import matches current workspace import", path=path)
            report["required_resources"].append(record)
            check(present, "Required runtime resource is packaged", path=path, category=category)

        for name in PRODUCTION_DATA:
            require("data/" + name, "production_definition", exact_source=True)
            if "data/" + name in resources:
                json.loads(resources["data/" + name])
        data_paths = sorted(name for name in resources if name.startswith("data/"))
        check(data_paths == sorted("data/" + name for name in PRODUCTION_DATA),
              "Only production JSON definitions are packaged", actual=data_paths)
        for path in ATTRIBUTION:
            require(path, "font_attribution", exact_source=True)

        required = set(LIVE_REFERENCE) | set(APPLICATION_RUNTIME)
        for folder in ("assets", "scenes", "scripts/audio", "scripts/core", "scripts/ui"):
            for file in (project / folder).rglob("*"):
                if file.is_file() and file.suffix.lower() in RESOURCE_SUFFIXES:
                    required.add(file.relative_to(project).as_posix())
        for path in sorted(required):
            category = ("application_runtime" if path in APPLICATION_RUNTIME
                        else "live_reference_art" if path in LIVE_REFERENCE else "runtime_resource")
            require(path, category)

        sfx_source = sorted(path.relative_to(project).as_posix() for path in (project / "assets/audio/sfx").rglob("*.wav"))
        sfx_packed = sorted(name[:-7] for name in resources if name.startswith("assets/audio/sfx/") and name.endswith(".wav.import"))
        check(len(sfx_source) == 21 and sfx_packed == sfx_source,
              "All and only the current 21 SFX WAV imports are packaged", expected=sfx_source, actual=sfx_packed)
        catalogue = (project / "scripts/audio/audio_catalogue.gd").read_text(encoding="utf-8-sig")
        catalogue_sfx = sorted(set(re.findall(r'"runtime_path":\s*"res://(assets/audio/sfx/[^"]+\.wav)"', catalogue)))
        check(catalogue_sfx == sfx_source, "Shipped GDScript catalogue source covers all 21 current SFX", actual=catalogue_sfx)
        music = sorted(name for name in resources if name.startswith("assets/audio/music/"))
        check(not music, "Unavailable music has no packaged substitute", paths=music)
        report["sfx_count"] = len(sfx_packed)
        report["resource_entry_count"] = len(resources)

        if resource_pack and not duplicates and not unsafe:
            resource_pack.parent.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(resource_pack, "w", compression=zipfile.ZIP_DEFLATED) as pack:
                for name, contents in sorted(resources.items()):
                    # Android command line and sparse-PCK index are platform
                    # containers, not resources needed by the desktop decoder.
                    if name not in {"_cl_", "assets.sparsepck"}:
                        pack.writestr(name, contents)
            report["resource_pack"] = {"path": str(resource_pack), "sha256": sha256(resource_pack.read_bytes()),
                                       "purpose": "Byte-identical APK resource payloads repacked for separate desktop Godot decoding; not a new Android build."}
    report["failures"] = [entry for entry in report["checks"] if not entry["passed"]]
    report["passed"] = not report["failures"]
    report["check_count"] = len(report["checks"])
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path, help="Actual exported debug APK")
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--report", type=Path, default=Path("output/qa/rc-021/package-contents.json"))
    parser.add_argument("--resource-pack", type=Path, help="Optionally write exact APK resources as a ZIP for verify_android_resources.gd")
    parser.add_argument("--expected-abi", action="append", help="Repeat for an explicitly approved extra ABI; defaults to arm64-v8a")
    args = parser.parse_args()
    apk, project, report_path = args.apk.resolve(), args.project_root.resolve(), args.report.resolve()
    resource_pack = args.resource_pack.resolve() if args.resource_pack else None
    if report_path == apk or resource_pack == apk or (resource_pack and resource_pack == report_path):
        parser.error("APK input, JSON report and optional resource ZIP must use distinct paths")
    try:
        report = audit(apk, project, set(args.expected_abi or ["arm64-v8a"]), resource_pack)
    except (OSError, ValueError, KeyError, UnicodeError, zipfile.BadZipFile) as error:
        print(f"Package audit could not complete: {error}", file=sys.stderr)
        return 2
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"{report['check_count']} package checks, {len(report['failures'])} failures; {report_path}")
    for failure in report["failures"]:
        print(json.dumps(failure), file=sys.stderr)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
