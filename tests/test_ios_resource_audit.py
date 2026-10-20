"""Focused PCK integrity and production-policy regressions (standard library)."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import struct
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from verify_ios_resources import audit_resources, read_pack  # noqa: E402


def make_pack(entries: list[tuple[str, bytes]]) -> bytes:
    """Small unencrypted PCK v4 fixture; not a game export."""
    base = 104
    payload = bytearray()
    directory = bytearray(struct.pack("<I", len(entries)))
    for name, content in entries:
        encoded = ("res://" + name).encode()
        padded = encoded + b"\0" * ((-len(encoded)) % 4)
        directory.extend(struct.pack("<I", len(padded)) + padded)
        directory.extend(struct.pack("<QQ", len(payload), len(content)))
        directory.extend(hashlib.md5(content).digest() + struct.pack("<I", 0))
        payload.extend(content)
    header = b"GDPC" + struct.pack("<5I2Q", 4, 4, 7, 2, 2, base, base + len(payload))
    return header.ljust(base, b"\0") + payload + directory


class PackIntegrityTests(unittest.TestCase):
    def read(self, data: bytes):
        evidence = Path(__file__).resolve().parents[1] / "output/qa/rc-022/resource-fixtures"
        evidence.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=evidence) as directory:
            path = Path(directory) / "fixture.pck"
            path.write_bytes(data)
            return read_pack(path)

    def test_valid_payload_has_exact_bytes(self):
        _, resources, records = self.read(make_pack([("data/a.json", b"{}")]))
        self.assertEqual(resources, {"data/a.json": b"{}"})
        self.assertEqual(records[0]["sha256"], hashlib.sha256(b"{}").hexdigest())

    def test_corrupt_data_fails_digest(self):
        data = bytearray(make_pack([("data/a.json", b"{}")]))
        data[104] ^= 1
        with self.assertRaisesRegex(ValueError, "MD5 mismatch"):
            self.read(bytes(data))

    def test_case_collision_rejected(self):
        with self.assertRaisesRegex(ValueError, "case-colliding"):
            self.read(make_pack([("data/A.json", b"{}"), ("data/a.json", b"{}")] ))

    def test_traversal_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unsafe"):
            self.read(make_pack([("../outside", b"no")]))

    def test_truncated_directory_rejected(self):
        with self.assertRaisesRegex(ValueError, "Truncated"):
            self.read(make_pack([("data/a.json", b"{}")])[:-7])


class ActualPackPolicyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = Path(__file__).resolve().parents[1]
        # Historical RC-022 artifacts remain evidence of that delivered source,
        # not fixtures that can satisfy today's changed runtime inventory.
        selected_pack = os.environ.get("RUNECAST_RESOURCE_TEST_PACK")
        pack = Path(selected_pack) if selected_pack else cls.root / "builds/ios/rc-024-resource-final/RuneCast.pck"
        if not pack.is_file():
            if selected_pack:
                raise FileNotFoundError(f"Explicit RUNECAST_RESOURCE_TEST_PACK is unavailable: {pack}")
            raise unittest.SkipTest("Current export PCK unavailable; set RUNECAST_RESOURCE_TEST_PACK to a fresh resource export")
        _, cls.resources, _ = read_pack(pack)

    def failures(self, resources):
        return [check for check in audit_resources(resources, self.root)["checks"] if not check["passed"]]

    def test_actual_export_passes(self):
        self.assertEqual(self.failures(self.resources), [])

    def test_missing_imported_audio_rejected_despite_workspace_source(self):
        resources = self.resources.copy()
        sample = next(name for name in resources if name.endswith(".sample"))
        self.assertTrue((self.root / sample).exists())
        del resources[sample]
        self.assertTrue(any("remap" in check["description"] for check in self.failures(resources)))

    def test_wrong_case_remap_rejected(self):
        resources = self.resources.copy()
        name = next(name for name in resources if name.endswith(".wav.import"))
        resources[name] = resources[name].replace(b"res://.godot/", b"res://.GODOT/")
        self.assertTrue(any("remap" in check["description"] for check in self.failures(resources)))

    def test_docs_leak_rejected(self):
        resources = {**self.resources, "docs/leak.json": b"{}"}
        self.assertTrue(any("excluded" in check["description"] for check in self.failures(resources)))

    def test_music_substitute_rejected(self):
        resources = {**self.resources, "assets/audio/music/substitute.ogg": b"not approved"}
        self.assertTrue(any("substitute" in check["description"] for check in self.failures(resources)))

    def test_missing_application_entry_or_run_model_rejected(self):
        for path in ("scenes/application.tscn", "scripts/ui/application_shell.gd", "scripts/core/run_state.gd"):
            with self.subTest(path=path):
                resources = self.resources.copy()
                # Exported scripts/scenes may resolve through compiled remaps.
                resources.pop(path, None)
                resources.pop(path + ".remap", None)
                self.assertTrue(any(check.get("path") == path for check in self.failures(resources)))


if __name__ == "__main__":
    unittest.main()
