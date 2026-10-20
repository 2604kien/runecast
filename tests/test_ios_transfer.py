"""Source transfer boundary checks; does not pretend to run macOS/iOS."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

SPEC = importlib.util.spec_from_file_location("transfer", Path(__file__).resolve().parents[1] / "tools/prepare_ios_transfer.py")
transfer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(transfer)
SCRATCH = Path(__file__).resolve().parents[1] / "output/qa/rc-022/transfer-test-tmp"
SCRATCH.mkdir(parents=True, exist_ok=True)


class TransferTests(unittest.TestCase):
    def test_round_trip_excludes_outputs_credentials_and_caches(self):
        with tempfile.TemporaryDirectory(dir=SCRATCH) as directory:
            root = Path(directory).resolve()
            for name in transfer.ROOT_FILES:
                (root / name).write_text("source", encoding="utf-8")
            for name in transfer.SOURCE_DIRS:
                (root / name).mkdir()
            for name in ("assets/ui/icon.svg", "scripts/main.gd", "tests/smoke.gd", "tools/ios.py",
                         "assets/ui/icon.svg.import", "docs/setup.md", "data/production.json",
                         ".git/config", ".godot/cache", ".tools/sdk.exe", "output/capture.png",
                         "builds/old.app", "source-assets/raw.png", "tools/__pycache__/ios.pyc",
                         "tools/.env", "tools/private.p12", "tools/signing-config.json",
                         "assets/profile.mobileprovision"):
                file = root / name
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_text("fixture", encoding="utf-8")
            archive, report = transfer.create(root)
            self.assertTrue(report["passed"])
            with zipfile.ZipFile(archive) as z:
                self.assertIn("assets/ui/icon.svg.import", z.namelist())
                self.assertIn("tests/smoke.gd", z.namelist())
                self.assertEqual(set(z.namelist()), transfer.ROOT_FILES | {
                    "assets/ui/icon.svg", "scripts/main.gd", "tests/smoke.gd", "tools/ios.py",
                    "assets/ui/icon.svg.import", "docs/setup.md", "data/production.json", transfer.MANIFEST})

    def test_rejects_unlisted_and_tampered_payload(self):
        for extra in (True, False):
            with self.subTest(extra=extra), tempfile.TemporaryDirectory(dir=SCRATCH) as directory:
                archive = Path(directory) / "bad.zip"
                files = [{"path": n, "bytes": 1, "sha256": transfer.sha256(b"x")} for n in transfer.ROOT_FILES]
                with zipfile.ZipFile(archive, "w") as z:
                    for row in files:
                        z.writestr(row["path"], b"x" if extra else b"y")
                    z.writestr(transfer.MANIFEST, json.dumps({"files": files}))
                    if extra:
                        z.writestr("tools/secret.p12", b"secret")
                with self.assertRaises(ValueError):
                    transfer.verify(archive)

    def test_path_boundaries(self):
        for path in ("/project.godot", "../project.godot", "tools/../secret", "tools\\a.py",
                     "tools/private.key", "tools/AuthKey.p8", "tools/.env", "tools/a:stream", ".git/config"):
            self.assertFalse(transfer.permitted(path), path)


if __name__ == "__main__":
    unittest.main()
