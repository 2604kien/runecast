#!/usr/bin/env python3
"""Audit and decode an actual Godot 4.7.2 iOS export PCK in isolation.

No Xcode, signing or device claim follows from this check. Static checks read the
PCK itself; the optional project root supplies expected source paths/content,
never fallback resources for the decoder. The pinned desktop engine decodes the
original PCK with a fresh empty working project and isolated user directories.
"""

from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import struct
import subprocess
import sys
import tempfile

from verify_android_package import (
    APPLICATION_RUNTIME, ATTRIBUTION, FORBIDDEN_FILES, FORBIDDEN_PREFIXES, FORBIDDEN_SUFFIXES,
    LIVE_REFERENCE, PRODUCTION_DATA, REMAP_PATH, RESOURCE_SUFFIXES, safe_name, sha256,
)

ENGINE = "4.7.2.stable.official.ed1daf0bf"


def read_pack(pack: Path) -> tuple[dict, dict[str, bytes], list[dict]]:
    """Read unencrypted standalone PCK v2/3/4 as used by pinned Godot.

    Layout: Godot 4.7.2 core/io/file_access_pack.cpp, PackedSourcePCK.
    Unsupported encryption, sparse bundles and patch entries fail closed.
    """
    data = pack.read_bytes()
    cursor = 0

    def take(size: int) -> bytes:
        nonlocal cursor
        if size < 0 or cursor + size > len(data):
            raise ValueError("Truncated PCK header/directory")
        result = data[cursor:cursor + size]
        cursor += size
        return result

    def number(fmt: str) -> int:
        return struct.unpack(fmt, take(struct.calcsize(fmt)))[0]

    if take(4) != b"GDPC":
        raise ValueError("Expected a standalone Godot PCK, not ZIP/executable")
    version = number("<I")
    engine = [number("<I") for _ in range(3)]
    if version not in (2, 3, 4) or engine != [4, 7, 2]:
        raise ValueError(f"Expected pinned 4.7.2 PCK v2/3/4; got {version}, {engine}")
    flags, file_base = number("<I"), number("<Q")
    if flags & ~2:
        raise ValueError(f"Unsupported encrypted/sparse PCK flags: {flags}")
    if version in (3, 4):
        directory = number("<Q")
        if directory < 104 or directory >= len(data):
            raise ValueError("Invalid PCK directory offset")
        cursor = directory
    else:
        take(64)
        directory = cursor
    count = number("<I")
    if count > 100000:
        raise ValueError("Unexpectedly large PCK directory")
    records = []
    for _ in range(count):
        path = take(number("<I")).rstrip(b"\0").decode("utf-8")
        path = path.removeprefix("res://")
        if not safe_name(path) or "\0" in path or any(part in ("", ".") for part in path.split("/")):
            raise ValueError(f"Unsafe/noncanonical PCK path: {path!r}")
        offset, size = file_base + number("<Q"), number("<Q")
        digest, entry_flags = take(16).hex(), number("<I")
        if entry_flags:
            raise ValueError(f"Unsupported encrypted/removed/delta PCK entry: {path}")
        if offset < file_base or offset + size > len(data):
            raise ValueError(f"Out-of-bounds PCK payload: {path}")
        records.append({"path": path, "offset": offset, "bytes": size, "md5": digest})
    names = [record["path"] for record in records]
    duplicates = [name for name, count in Counter(names).items() if count != 1]
    folded = [name for name, count in Counter(name.casefold() for name in names).items() if count != 1]
    if duplicates or folded:
        raise ValueError(f"Duplicate/case-colliding PCK paths: {duplicates + folded}")
    resources = {}
    for record in records:
        start, end = record["offset"], record["offset"] + record["bytes"]
        if start < (104 if version in (3, 4) else 96) or (start < cursor and end > directory):
            raise ValueError(f"PCK payload overlaps header/directory: {record['path']}")
        content = data[start:end]
        if hashlib.md5(content).hexdigest() != record["md5"]:
            raise ValueError(f"PCK payload MD5 mismatch: {record['path']}")
        record["sha256"] = sha256(content)
        resources[record["path"]] = content
    ordered_ranges = sorted((r["offset"], r["offset"] + r["bytes"]) for r in records if r["bytes"])
    if any(left[1] > right[0] for left, right in zip(ordered_ranges, ordered_ranges[1:])):
        raise ValueError("Overlapping PCK payload entries")
    return {"format": version, "engine": engine, "flags": flags, "entry_count": count}, resources, records


def audit_resources(resources: dict[str, bytes], project: Path) -> dict:
    report = {"checks": [], "required_resources": []}

    def check(ok: bool, description: str, **details: object) -> None:
        report["checks"].append({"passed": bool(ok), "description": description, **details})

    check(bool(resources.get("project.binary")), "PCK contains exported Godot project settings")
    unknown = sorted(name for name in resources
                     if not name.startswith(("assets/", "scenes/", "scripts/", "data/", ".godot/"))
                     and name != "project.binary")
    check(not unknown, "Only expected runtime roots are packaged", paths=unknown)
    forbidden = sorted(name for name in resources if name.startswith(FORBIDDEN_PREFIXES)
                       or name in FORBIDDEN_FILES
                       or PurePosixPath(name).suffix.lower() in FORBIDDEN_SUFFIXES
                       or PurePosixPath(name).suffix.lower() in {".mobileprovision", ".cer", ".p8", ".xcarchive"})
    check(not forbidden, "Development/source/signing material is excluded", paths=forbidden)
    remaps = {}
    for name, content in sorted(resources.items()):
        if name.endswith((".import", ".remap")):
            targets = REMAP_PATH.findall(content.decode("utf-8"))
            remaps[name] = targets
            check(bool(targets) and all(target in resources and resources[target] for target in targets),
                  "Resource remap resolves with exact path casing to packaged data", path=name, targets=targets)

    def require(path: str, category: str, exact_source: bool = False) -> None:
        targets = [path] if path in resources else remaps.get(path + ".remap", remaps.get(path + ".import", []))
        present = bool(targets) and all(name in resources and resources[name] for name in targets)
        report["required_resources"].append({"path": path, "category": category,
                                             "packaged_paths": targets, "present": bool(present)})
        check(present, "Required runtime resource is packaged with exact casing", path=path, category=category)
        if exact_source and present:
            check(path in resources and resources[path] == (project / path).read_bytes(),
                  "Packaged plain-text data matches expected source", path=path)

    for name in PRODUCTION_DATA:
        path = "data/" + name
        require(path, "production_definition", exact_source=True)
        if path in resources:
            json.loads(resources[path])
    data_paths = sorted(name for name in resources if name.startswith("data/"))
    check(data_paths == sorted("data/" + name for name in PRODUCTION_DATA),
          "Only the eight production JSON definitions are packaged", actual=data_paths)
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
    sfx = sorted(path.relative_to(project).as_posix() for path in (project / "assets/audio/sfx").rglob("*.wav"))
    packed_sfx = sorted(name[:-7] for name in resources if name.startswith("assets/audio/sfx/") and name.endswith(".wav.import"))
    check(len(sfx) == 21 and packed_sfx == sfx, "All and only the current 21 SFX imports are packaged", actual=packed_sfx)
    catalogue = (project / "scripts/audio/audio_catalogue.gd").read_text(encoding="utf-8-sig")
    catalogue_sfx = sorted(set(re.findall(r'"runtime_path":\s*"res://(assets/audio/sfx/[^\"]+\.wav)"', catalogue)))
    check(catalogue_sfx == sfx, "Runtime catalogue covers all 21 current SFX", actual=catalogue_sfx)
    music = sorted(name for name in resources if name.startswith("assets/audio/music/"))
    check(not music, "Pending music has no packaged substitute", paths=music)
    report["sfx_count"] = len(packed_sfx)
    report["resource_entry_count"] = len(resources)
    return report


def decode(pack: Path, engine: Path, evidence: Path) -> dict:
    version = subprocess.run([str(engine), "--version"], capture_output=True, text=True, timeout=30)
    actual = version.stdout.strip()
    if version.returncode or actual != ENGINE:
        raise ValueError(f"Decoder requires {ENGINE}; actual {actual!r}")
    # The main pack and empty --path prevent fallback to the project. A fresh
    # HOME/XDG/APPDATA also prevents inherited settings from changing the probe.
    with tempfile.TemporaryDirectory(prefix="ios-payload-empty-", dir=evidence) as folder:
        empty = Path(folder)
        env = os.environ.copy()
        user = empty / "user"
        user.mkdir()
        for name in ("HOME", "APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
            env[name] = str(user)
        log = evidence / "ios-resource-probe.log"
        command = [str(engine), "--headless", "--path", str(empty), "--main-pack", str(pack),
                   "--script", str(Path(__file__).with_name("verify_android_resources.gd")),
                   "--log-file", str(log), "--", "--payload-label=iOS"]
        result = subprocess.run(command, cwd=empty, env=env, capture_output=True, text=True,
                                encoding="utf-8", errors="replace", timeout=120)
        output = result.stdout + result.stderr
        (evidence / "ios-resource-probe-console.txt").write_text(output, encoding="utf-8")
        summary = re.search(r"(\d+) iOS payload desktop decode checks, (\d+) failures", output)
        errors = [line for line in output.splitlines() if "ERROR:" in line or "SCRIPT ERROR:" in line]
        passed = result.returncode == 0 and bool(summary) and int(summary[1]) == 60 and int(summary[2]) == 0 and not errors
        return {"passed": passed, "engine": actual, "command": command,
                "fresh_empty_project": True, "isolated_user_data": True,
                "workspace_resource_fallback": False, "return_code": result.returncode,
                "check_count": int(summary[1]) if summary else 0,
                "failure_count": int(summary[2]) if summary else None,
                "engine_errors": errors, "log": str(log),
                "scope": "Desktop decoding of this exact PCK; no iOS native execution or listening acceptance."}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pack", type=Path, required=True)
    parser.add_argument("--engine", type=Path, required=True, help="Pinned Standard Godot executable for isolated desktop decoding")
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    pack, engine, project, report_path = (value.resolve() for value in (args.pack, args.engine, args.project_root, args.report))
    if report_path in (pack, engine):
        parser.error("Report must not overwrite the input pack or engine")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report = {"schema": "runecast_ios_resources_v1", "checked_at_utc": datetime.now(timezone.utc).isoformat(),
              "pack": str(pack), "scope": "Exported resources only, not an Xcode project, built app or physical-device acceptance.",
              "passed": False}
    try:
        header, resources, entries = read_pack(pack)
        report.update({"pack_size_bytes": pack.stat().st_size, "pack_sha256": sha256(pack.read_bytes()),
                       "pack_header": header, "entries": entries, "payload_integrity_passed": True})
        report.update(audit_resources(resources, project))
        report["failures"] = [entry for entry in report["checks"] if not entry["passed"]]
        report["check_count"] = len(report["checks"])
        # Skip executing a payload that fails the static production policy.
        if not report["failures"]:
            report["decode"] = decode(pack, engine, report_path.parent)
        report["passed"] = not report["failures"] and report.get("decode", {}).get("passed", False)
    except (OSError, ValueError, KeyError, UnicodeError, struct.error, subprocess.SubprocessError) as error:
        report["error"] = str(error)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"{report.get('check_count', 0)} iOS resource checks; passed={report['passed']}; {report_path}")
    if not report["passed"]:
        print(json.dumps({key: report[key] for key in ("error", "failures", "decode") if key in report}), file=sys.stderr)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
