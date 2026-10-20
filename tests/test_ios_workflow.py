"""Host-independent failure-path regressions; these do not exercise Xcode/iOS."""
import argparse
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("ios_workflow", Path(__file__).resolve().parents[1] / "tools/ios.py")
ios = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ios)


class IOSWorkflowTests(unittest.TestCase):
    def setUp(self):
        temporary_root = Path(__file__).resolve().parents[1] / "output/qa/rc-022/tests-temp"
        temporary_root.mkdir(parents=True, exist_ok=True)
        self.directory = tempfile.TemporaryDirectory(dir=temporary_root)
        self.addCleanup(self.directory.cleanup)
        self.base = Path(self.directory.name)
        self.temp_patch = patch.object(ios.tempfile, "tempdir", str(self.base))
        self.temp_patch.start()
        self.addCleanup(self.temp_patch.stop)
        self.root = self.base / "project"
        self.root.mkdir()
        self.identity = {"owner_approved": True, "team_id": "A1B2C3D4E5", "bundle_identifier": "dev.owner.runecast"}
        self.external = self.base / "identity.json"
        self.external.write_text(json.dumps(self.identity))

    def args(self, action="preflight"):
        return argparse.Namespace(action=action, developer_dir=None, godot=None, templates=None,
                                  identity=None, device=None, app=None, manifest=None)

    def test_external_owner_identity_loads(self):
        self.assertEqual(ios.load_identity(self.external, self.root), self.identity)

    def test_identity_in_project_is_rejected(self):
        local = self.root / "identity.json"
        local.write_text(self.external.read_text())
        with self.assertRaisesRegex(ios.WorkflowError, "outside"):
            ios.load_identity(local, self.root)

    def test_placeholder_and_wildcard_identity_rejected(self):
        for bundle in ("com.example.runecast", "org.example.runecast", "dev.owner.*", "invalid.runecast", "bad\nidentity"):
            with self.subTest(bundle=bundle):
                self.external.write_text(json.dumps(dict(self.identity, bundle_identifier=bundle)))
                with self.assertRaises(ios.WorkflowError):
                    ios.load_identity(self.external, self.root)

    def test_unapproved_identity_and_credential_fields_rejected(self):
        for config in (dict(self.identity, owner_approved=False), dict(self.identity, password="must not enter sources")):
            self.external.write_text(json.dumps(config))
            with self.assertRaises(ios.WorkflowError):
                ios.load_identity(self.external, self.root)

    def test_staged_options_preserve_android_verbatim(self):
        source = (Path(__file__).resolve().parents[1] / "export_presets.cfg").read_text()
        android = source.split("[preset.1]")[0]
        updated, name = ios.staged_presets(source, self.identity, self.base / "ios.zip")
        self.assertEqual(name, "iOS")
        self.assertEqual(updated.split("[preset.1]")[0], android)
        self.assertIn('application/bundle_identifier="dev.owner.runecast"', updated)
        self.assertIn('application/export_project_only=true', updated)
        self.assertIn('application/delete_old_export_files_unconditionally=false', updated)
        self.assertIn('application/targeted_device_family=0', updated)
        self.assertNotIn('application/bundle_identifier="dev.owner.runecast"', source)

    def test_ambiguous_ios_preset_rejected(self):
        text = '[preset.0]\nname="A"\nplatform="iOS"\n[preset.0.options]\n[preset.1]\nname="B"\nplatform="iOS"\n[preset.1.options]\n'
        with self.assertRaisesRegex(ios.WorkflowError, "exactly one"):
            ios.staged_presets(text, self.identity, self.base / "ios.zip")

    def info(self):
        return {"CFBundleIdentifier": self.identity["bundle_identifier"], "CFBundleShortVersionString": "0.1.0",
                "CFBundleVersion": "1", "CFBundleSupportedPlatforms": ["iPhoneOS"], "UIDeviceFamily": [1],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"], "MinimumOSVersion": "15.0",
                "CFBundleExecutable": "RuneCast"}

    def test_valid_physical_app_metadata(self):
        ios.validate_info(self.info(), self.identity)

    def test_simulator_tablet_landscape_wrong_identity_rejected(self):
        changes = ({"CFBundleSupportedPlatforms": ["iPhoneSimulator"]}, {"UIDeviceFamily": [1, 2]},
                   {"UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationLandscapeLeft"]},
                   {"CFBundleIdentifier": "dev.someoneelse.runecast"}, {"CFBundleExecutable": "../outside"},
                   {"MinimumOSVersion": "16.0"})
        for change in changes:
            with self.subTest(change=change):
                with self.assertRaises(ios.WorkflowError):
                    ios.validate_info(dict(self.info(), **change), self.identity)

    def test_windows_fail_closed_with_persisted_evidence(self):
        with patch.object(ios, "ROOT", self.root), patch.object(ios.platform, "system", return_value="Windows"):
            self.assertEqual(ios.main(["preflight"]), 2)
        records = list((self.root / "output/qa/rc-022").glob("*/workflow.json"))
        self.assertEqual(len(records), 1)
        record = json.loads(records[0].read_text())
        self.assertFalse(record["passed"])
        self.assertEqual(record["host_system"], "Windows")
        self.assertIn("authorized Mac", record["failure"])

    def test_runs_never_reuse_existing_output(self):
        with patch.object(ios, "ROOT", self.root):
            first, second = ios.Workflow(self.args()), ios.Workflow(self.args())
        self.assertNotEqual(first.evidence, second.evidence)
        self.assertTrue(first.evidence.is_dir() and second.evidence.is_dir())

    def test_stage_copies_only_runtime_roots_and_preserves_original_preset(self):
        for directory in (*ios.RUNTIME_ROOTS, ".godot", ".tools", "docs"):
            (self.root / directory).mkdir()
            (self.root / directory / "sample.txt").write_text(directory)
        preset = '[preset.0]\nname="Android"\nplatform="Android"\n[preset.0.options]\n[preset.1]\nname="iOS"\nplatform="iOS"\n[preset.1.options]\napplication/bundle_identifier=""\n'
        (self.root / "project.godot").write_text("config_version=5\n")
        (self.root / "export_presets.cfg").write_text(preset)
        with patch.object(ios, "ROOT", self.root):
            workflow = ios.Workflow(self.args("import"))
            workflow.identity, workflow.templates = self.identity, self.base / "templates"
            staged = workflow.stage()
        self.assertEqual(set(path.name for path in staged.iterdir()), {*ios.RUNTIME_ROOTS, "project.godot", "export_presets.cfg"})
        self.assertEqual((self.root / "export_presets.cfg").read_text(), preset)
        self.assertIn('application/bundle_identifier="dev.owner.runecast"', (staged / "export_presets.cfg").read_text())

    def test_zero_exit_with_godot_error_is_failure(self):
        with patch.object(ios, "ROOT", self.root):
            workflow = ios.Workflow(self.args())
        result = ios.subprocess.CompletedProcess(["godot"], 0, "SCRIPT ERROR: parse failed\n")
        with patch.object(ios.subprocess, "run", return_value=result):
            with self.assertRaisesRegex(ios.WorkflowError, "despite zero"):
                workflow.command(["godot"], "import", check_errors=True)

    def test_devicectl_zero_exit_missing_json_is_failure(self):
        with patch.object(ios, "ROOT", self.root):
            workflow = ios.Workflow(self.args())
        with patch.object(workflow, "command", return_value="success"):
            with self.assertRaises(ios.WorkflowError):
                workflow.device_command(["list", "devices"], "devices")

    def test_devicectl_failure_outcome_rejected(self):
        with patch.object(ios, "ROOT", self.root):
            workflow = ios.Workflow(self.args())
        def fake_command(args, *positional, **kwargs):
            Path(args[-1]).write_text(json.dumps({"info": {"outcome": "failure"}, "result": {}}))
            return ""
        with patch.object(workflow, "command", side_effect=fake_command):
            with self.assertRaisesRegex(ios.WorkflowError, "not successful"):
                workflow.device_command(["list", "devices"], "devices")

    def deployment_fixture(self, action, record_changes=None):
        args = self.args(action)
        with patch.object(ios, "ROOT", self.root):
            workflow = ios.Workflow(args)
        workflow.identity = self.identity
        workflow.report["identity"] = {key: self.identity[key] for key in ("team_id", "bundle_identifier")}
        record = {"passed": True, "development_signed": True, "action": "install", "installation_verified": True,
                  "identity": workflow.report["identity"], "app": str(self.root / "builds/ios/run/RuneCast.app"),
                  "app_file_manifest_sha256": "verified-original", "device": {"udid": "selected-phone"}}
        record.update(record_changes or {})
        manifest = workflow.evidence / "prior-workflow.json"
        manifest.write_text(json.dumps(record))
        args.manifest = str(manifest)
        return workflow

    def test_launch_refuses_build_manifest_without_install_receipt(self):
        workflow = self.deployment_fixture("launch", {"action": "build", "installation_verified": False})
        with patch.object(ios, "ROOT", self.root):
            with self.assertRaisesRegex(ios.WorkflowError, "install workflow"):
                workflow.deployment()

    def test_install_refuses_changed_full_app_manifest(self):
        workflow = self.deployment_fixture("install")
        def changed_app(_):
            workflow.report["app_file_manifest_sha256"] = "modified-info-or-resource"
        with patch.object(ios, "ROOT", self.root), patch.object(workflow, "inspect", side_effect=changed_app):
            with self.assertRaisesRegex(ios.WorkflowError, "App contents changed"):
                workflow.deployment()

    def test_launch_refuses_other_phone_install_receipt(self):
        workflow = self.deployment_fixture("launch")
        def unchanged_app(_):
            workflow.report["app_file_manifest_sha256"] = "verified-original"
        with patch.object(ios, "ROOT", self.root), patch.object(workflow, "inspect", side_effect=unchanged_app), \
                patch.object(workflow, "device", return_value={"udid": "another-phone"}):
            with self.assertRaisesRegex(ios.WorkflowError, "different iPhone"):
                workflow.deployment()


if __name__ == "__main__":
    unittest.main()
