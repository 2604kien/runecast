#!/usr/bin/env python3
"""Make/verify a source-only Mac handoff ZIP, without Git or generated caches."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import stat
import sys
import uuid
import zipfile

ROOT_FILES = {"project.godot", "export_presets.cfg", "README.md"}
SOURCE_DIRS = {"assets", "data", "scenes", "scripts", "tests", "tools", "docs"}
BLOCKED_PARTS = {".git", ".godot", ".tools", ".local", ".codex", ".agents",
                 "__pycache__", "node_modules", "builds", "output", "source-assets"}
BLOCKED_SUFFIXES = {".pyc", ".pyo", ".p12", ".pfx", ".pem", ".key", ".keystore",
                    ".jks", ".p8", ".p7b", ".csr", ".der", ".mobileprovision",
                    ".provisionprofile", ".cer", ".cert"}
MANIFEST = "transfer-manifest.json"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def permitted(name: str) -> bool:
    p = PurePosixPath(name)
    parts = tuple(part.lower() for part in p.parts)
    return (not p.is_absolute() and "\\" not in name and ":" not in name
            and ".." not in parts and not any(part in BLOCKED_PARTS for part in parts)
            and p.suffix.lower() not in BLOCKED_SUFFIXES
            and not any(part.startswith(".") and part not in {".gdignore"} for part in parts)
            and not any(word in p.name.lower() for word in ("credential", "signing", "secret"))
            and (name in ROOT_FILES or (len(parts) > 1 and p.parts[0] in SOURCE_DIRS)))


def source_files(root: Path) -> list[Path]:
    files = [root / name for name in sorted(ROOT_FILES)]
    for directory in sorted(SOURCE_DIRS):
        base = root / directory
        if base.is_symlink():
            raise ValueError(f"Source directory is a symlink: {directory}")
        if not base.is_dir():
            raise ValueError(f"Required source directory missing: {directory}")
        # Walk without following directory symlinks, including Windows junctions.
        import os
        for current, directories, names in os.walk(base, followlinks=False):
            here = Path(current)
            directories[:] = sorted(d for d in directories
                                    if d.lower() not in BLOCKED_PARTS and not d.startswith(".")
                                    and not (here / d).is_symlink()
                                    and not (hasattr(Path, "is_junction") and (here / d).is_junction()))
            for name in sorted(names):
                file = here / name
                if permitted(file.relative_to(root).as_posix()):
                    if file.is_symlink() or not file.resolve().is_relative_to(root):
                        raise ValueError("Source file escapes project or is a symlink")
                    files.append(file)
    for file in files:
        if file.is_symlink() or not file.resolve().is_relative_to(root):
            raise ValueError("Source file escapes project or is a symlink")
    return sorted(files)


def verify(archive: Path) -> dict:
    with zipfile.ZipFile(archive) as z:
        names = z.namelist()
        if len(names) != len(set(n.casefold() for n in names)):
            raise ValueError("Duplicate or case-colliding ZIP paths")
        manifest = json.loads(z.read(MANIFEST))
        expected = {row["path"]: row for row in manifest["files"]}
        if len(expected) != len(manifest["files"]) or set(names) != set(expected) | {MANIFEST}:
            raise ValueError("ZIP inventory differs from manifest")
        for name, row in expected.items():
            if not permitted(name):
                raise ValueError(f"Forbidden transfer path: {name}")
            info = z.getinfo(name)
            if stat.S_ISLNK(info.external_attr >> 16):
                raise ValueError("Transfer contains a symlink")
            data = z.read(name)
            if len(data) != row["bytes"] or sha256(data) != row["sha256"]:
                raise ValueError(f"Transfer hash mismatch: {name}")
        if not ROOT_FILES.issubset(expected):
            raise ValueError("Transfer lacks project root files")
    return {"passed": True, "files": len(expected), "bytes": archive.stat().st_size,
            "sha256": sha256(archive.read_bytes()), "archive": str(archive),
            "scope": "Source transfer integrity only; no iOS build/install/device claim"}


def create(root: Path) -> tuple[Path, dict]:
    folder = root / "builds" / "ios" / ("transfer-" + uuid.uuid4().hex[:12])
    folder.mkdir(parents=True, exist_ok=False)
    archive = folder / "RuneCast-source.zip"
    manifest = {"purpose": "Source-only transfer for RC-022 Mac setup; not a shipped payload",
                "excluded": "Git metadata, caches, SDKs, signing material, source masters, previous outputs",
                "files": []}
    with zipfile.ZipFile(archive, "x", compression=zipfile.ZIP_DEFLATED) as z:
        for file in source_files(root):
            name = file.relative_to(root).as_posix()
            data = file.read_bytes()
            manifest["files"].append({"path": name, "bytes": len(data), "sha256": sha256(data)})
            z.writestr(name, data)
        z.writestr(MANIFEST, json.dumps(manifest, indent=2) + "\n")
    return archive, verify(archive)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify", type=Path, help="Verify an existing archive without extracting it")
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    try:
        root = args.project_root.resolve()
        if args.verify:
            report = verify(args.verify.resolve())
        else:
            archive, report = create(root)
            evidence = root / "output" / "qa" / "rc-022" / archive.parent.name
            evidence.mkdir(parents=True, exist_ok=False)
            (evidence / "transfer.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(report, indent=2))
        return 0
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        print(f"Source transfer failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
