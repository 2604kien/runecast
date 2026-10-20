#!/usr/bin/env python3
"""Scoped iPhone development workflow (Python 3.10+, standard library).

No downloads, account login, certificate changes, global Xcode selection, release
archive, uninstall, or data clearing. Source presets are never rewritten. Every
import/export/build uses a new staged project beneath builds/ios. Installation
and launch require an explicit device and a previously verified build manifest.
"""
from __future__ import annotations

import argparse
import configparser
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import plistlib
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import uuid
import zipfile

ROOT = Path(__file__).resolve().parent.parent
ENGINE = "4.7.2.stable.official.ed1daf0bf"
TEMPLATE_VERSION = "4.7.2.stable"
MIN_IOS = "15.0"
RUNTIME_ROOTS = ("assets", "data", "scenes", "scripts")


class WorkflowError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise WorkflowError(message)


def digest(path: Path) -> str:
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def under(path: Path, parent: Path) -> bool:
    return path.resolve().is_relative_to(parent.resolve())


def read_json(path: Path) -> dict:
    try:
        result = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, ValueError) as error:
        raise WorkflowError(f"Cannot read JSON: {path.name}") from error
    require(isinstance(result, dict), f"Expected a JSON object: {path.name}")
    return result


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, default=str) + "\n", encoding="utf-8")


def load_identity(path: Path, root: Path = ROOT) -> dict:
    require(not under(path, root), "Identity config must remain outside the project.")
    config = read_json(path)
    require(set(config) == {"owner_approved", "team_id", "bundle_identifier"},
            "Identity JSON requires only owner_approved, team_id and bundle_identifier; do not put credentials in it.")
    require(config["owner_approved"] is True, "The owner must approve this development identity first.")
    team, bundle = config["team_id"], config["bundle_identifier"]
    require(isinstance(team, str) and bool(re.fullmatch(r"[A-Z0-9]{10}", team)), "Team ID must be 10 uppercase letters/digits.")
    require(isinstance(bundle, str) and bool(re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle)),
            "Bundle identifier must be an explicit reverse-DNS identifier without wildcards.")
    require(not bundle.lower().startswith(("com.example.", "org.example.", "com.yourcompany.", "invalid.")),
            "Placeholder bundle identifiers are not approved development identities.")
    return config


def staged_presets(text: str, identity: dict, template: Path) -> tuple[str, str]:
    """Edit a COPY only; preserve the Android section and every source setting."""
    cfg = configparser.ConfigParser(interpolation=None, strict=True)
    cfg.optionxform = str
    cfg.read_string(text)
    matches = [section for section in cfg.sections()
               if re.fullmatch(r"preset\.\d+", section) and cfg[section].get("platform") == '"iOS"']
    require(len(matches) == 1, "Expected exactly one iOS export preset.")
    section = matches[0]
    name = json.loads(cfg[section]["name"])
    options = section + ".options"
    require(options in cfg, "iOS export options are missing.")
    replacements = {
        "application/bundle_identifier": json.dumps(identity["bundle_identifier"]),
        "application/app_store_team_id": json.dumps(identity["team_id"]),
        "application/export_project_only": "true",
        "application/delete_old_export_files_unconditionally": "false",
        "application/export_method_debug": "1",
        "application/code_sign_identity_debug": '"Apple Development"',
        "application/provisioning_profile_uuid_debug": '""',
        "application/provisioning_profile_specifier_debug": '""',
        "application/targeted_device_family": "0",
        "application/min_ios_version": json.dumps(MIN_IOS),
        "custom_template/debug": json.dumps(str(template)),
    }
    # Replace only the iOS options block; ConfigParser.write would also reformat Android.
    pattern = re.compile(r"(?ms)^\[" + re.escape(options) + r"\]\s*\n(.*?)(?=^\[|\Z)")
    match = pattern.search(text)
    require(match is not None, "Could not find iOS options block.")
    body = match.group(1)
    for key, value in replacements.items():
        line = key + "=" + value
        field = re.compile(r"(?m)^" + re.escape(key) + r"\s*=.*$")
        body = field.sub(lambda _: line, body) if field.search(body) else body.rstrip() + "\n" + line + "\n"
    return text[:match.start(1)] + body + text[match.end(1):], name


def validate_info(info: dict, identity: dict) -> None:
    require(info.get("CFBundleIdentifier") == identity["bundle_identifier"], "Built app has the wrong bundle identifier.")
    require(info.get("CFBundleShortVersionString") == "0.1.0" and info.get("CFBundleVersion") == "1", "Built app version must be 0.1.0 / 1.")
    require(info.get("CFBundleSupportedPlatforms") == ["iPhoneOS"], "Expected a physical iPhoneOS app, not a simulator product.")
    require(info.get("UIDeviceFamily") == [1], "App unexpectedly includes tablet or other device families.")
    require(info.get("UISupportedInterfaceOrientations") == ["UIInterfaceOrientationPortrait"], "App must support portrait only.")
    require(info.get("MinimumOSVersion") == MIN_IOS, "Built deployment target differs from the recorded iOS 15.0 floor.")
    executable = info.get("CFBundleExecutable", "")
    require(isinstance(executable, str) and executable and Path(executable).name == executable,
            "App has an invalid executable name.")


class Workflow:
    def __init__(self, args: argparse.Namespace):
        self.args = args
        self.run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
        self.evidence = ROOT / "output/qa/rc-022" / self.run_id
        require(under(self.evidence, ROOT / "output/qa/rc-022"), "Evidence directory escapes task output.")
        self.evidence.mkdir(parents=True, exist_ok=False)
        self.env = os.environ.copy()
        if args.developer_dir:
            selected = Path(args.developer_dir).expanduser().resolve()
            require(selected.is_dir(), "--developer-dir must name an existing Xcode Contents/Developer directory.")
            self.env["DEVELOPER_DIR"] = str(selected)
        self.report = {"schema": "runecast_ios_workflow_v1", "action": args.action,
                       "checked_at_utc": datetime.now(timezone.utc).isoformat(),
                       "host_system": platform.system(), "host_architecture": platform.machine(),
                       "passed": False, "physical_acceptance": "pending; commands cannot establish touch/audio/lifecycle acceptance"}
        self.identity = None
        self.engine = None

    def command(self, args: list, name: str | None = None, *, env: dict | None = None,
                timeout: int = 120, check_errors: bool = False, stdout_only: bool = False) -> str:
        try:
            completed = subprocess.run([str(item) for item in args], cwd=ROOT, env=env or self.env,
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       text=True, encoding="utf-8", errors="replace", timeout=timeout, check=False)
        except (OSError, subprocess.TimeoutExpired) as error:
            raise WorkflowError(f"{Path(str(args[0])).name} could not finish; check installed tools or timeout ({timeout}s).") from error
        combined = completed.stdout + (completed.stderr or "")
        if name:
            (self.evidence / (name + ".txt")).write_text(combined, encoding="utf-8")
        require(completed.returncode == 0, f"{Path(str(args[0])).name} failed ({completed.returncode}); see {name or 'tool/account setup'}.")
        require(not check_errors or not re.search(r"(?m)^(?:SCRIPT )?ERROR:", combined), f"Godot reported errors despite zero exit; see {name}.")
        return (completed.stdout if stdout_only else combined).strip()

    def mac(self) -> None:
        require(platform.system() == "Darwin", "A locally authorized Mac with Xcode is required. Windows preparation is not an iOS build.")
        self.report["macos"] = self.command(["/usr/bin/sw_vers"], "macos-version")
        self.report["mac_model"] = self.command(["/usr/sbin/sysctl", "-n", "hw.model"], "mac-model")
        self.report["selected_developer_dir"] = self.env.get("DEVELOPER_DIR") or self.command(["/usr/bin/xcode-select", "-p"])
        self.report["xcode"] = self.command(["/usr/bin/xcrun", "xcodebuild", "-version"], "xcode-version")
        sdk = self.command(["/usr/bin/xcrun", "--sdk", "iphoneos", "--show-sdk-path"], "iphoneos-sdk-path")
        require(Path(sdk).is_dir(), "Selected iPhoneOS SDK path is missing.")
        self.report["iphoneos_sdk"] = self.command(["/usr/bin/xcrun", "--sdk", "iphoneos", "--show-sdk-version"], "iphoneos-sdk-version")
        self.report["iphoneos_sdk_build"] = self.command(["/usr/bin/xcrun", "--sdk", "iphoneos", "--show-sdk-build-version"], "iphoneos-sdk-build")
        require(int(self.report["iphoneos_sdk"].split(".")[0]) >= 15, "Selected SDK cannot support the declared iOS 15.0 deployment target.")
        self.report["deployment_target"] = MIN_IOS

    def preflight(self) -> None:
        self.mac()
        require(self.args.godot, "Pass --godot /absolute/path/Godot.app/Contents/MacOS/Godot for the pinned Standard editor.")
        self.engine = Path(self.args.godot).expanduser().resolve()
        require(self.engine.is_file() and os.access(self.engine, os.X_OK), "Selected Godot executable is missing or not executable.")
        version = self.command([self.engine, "--version"], "godot-version")
        require(version == ENGINE, f"Godot must be exactly {ENGINE}; do not upgrade or mix templates.")
        require(self.args.templates, "Pass --templates DIRECTORY containing matching version.txt and ios.zip.")
        self.templates = Path(self.args.templates).expanduser().resolve()
        require((self.templates / "version.txt").is_file() and (self.templates / "ios.zip").is_file(), "Matching iOS template files are missing; Windows Android setup did not install them.")
        require((self.templates / "version.txt").read_text().strip() == TEMPLATE_VERSION, "Export template version does not match the editor.")
        template_hash = digest(self.templates / "ios.zip")
        lock = read_json(ROOT / "tools/ios-toolchain.json")
        require(template_hash == lock["templates"]["ios_zip_sha256"], "ios.zip is not the verified official 4.7.2 template.")
        with zipfile.ZipFile(self.templates / "ios.zip") as archive:
            require(archive.testzip() is None, "iOS template ZIP CRC verification failed.")
        self.report["godot_version"] = version
        self.report["godot_sha256"] = digest(self.engine)
        self.report["template_version"] = TEMPLATE_VERSION
        self.report["ios_template_sha256"] = template_hash
        require(self.args.identity, "Pass --identity /external/path/ios-development.json after the owner approves a Team ID and bundle identifier.")
        self.identity = load_identity(Path(self.args.identity).expanduser().resolve())
        self.report["identity"] = {key: self.identity[key] for key in ("team_id", "bundle_identifier")}
        # Read only. Names, certificate fingerprints and raw profile data are not retained.
        identities = self.command(["/usr/bin/security", "find-identity", "-v", "-p", "codesigning"])
        # The parenthesized common-name suffix can be a developer ID, not Team ID.
        # Team membership is verified from the built signature/profile, not inferred here.
        matches = [line for line in identities.splitlines()
                   if re.search(r'"(?:Apple Development|iPhone Developer):', line)]
        require(bool(matches), "No usable development signing identity. Owner must configure signing in Xcode; this helper creates no certificates.")
        self.report["usable_development_signing_identities"] = len(matches)
        self.report["signing_team_validation"] = "Pending until the built signature and embedded profile are inspected."
        self.report["provisioning"] = "Existing local profiles only; owner handles Xcode login/consent. No automatic provisioning updates requested."

    def stage(self) -> Path:
        build = ROOT / "builds/ios" / self.run_id
        require(under(build, ROOT / "builds/ios"), "Build directory escapes builds/ios.")
        build.mkdir(parents=True, exist_ok=False)
        source = build / "source"
        source.mkdir()
        # Refuse symlinks instead of copying material outside these approved source roots.
        for directory in RUNTIME_ROOTS:
            origin = ROOT / directory
            require(origin.is_dir() and not origin.is_symlink(), f"Runtime directory unavailable: {directory}")
            require(not any(item.is_symlink() for item in origin.rglob("*")), f"Runtime directory contains a symlink: {directory}")
            shutil.copytree(origin, source / directory)
        shutil.copy2(ROOT / "project.godot", source / "project.godot")
        text, self.preset_name = staged_presets((ROOT / "export_presets.cfg").read_text(encoding="utf-8"), self.identity, self.templates / "ios.zip")
        (source / "export_presets.cfg").write_text(text, encoding="utf-8")
        self.build = build
        self.source = source
        self.report["build_directory"] = str(build)
        self.report["source_settings_sha256"] = {name: digest(ROOT / name) for name in ("project.godot", "export_presets.cfg")}
        return source

    def import_project(self) -> Path:
        source = self.stage()
        self.godot_env = self.env.copy()
        home = self.build / "godot-home"
        home.mkdir()
        # Isolate editor/runtime preferences. Custom ios.zip bypasses implicit template discovery.
        self.godot_env.update(HOME=str(home), XDG_DATA_HOME=str(home / "data"), XDG_CONFIG_HOME=str(home / "config"))
        self.command([self.engine, "--headless", "--path", source, "--editor", "--import"], "godot-import",
                     env=self.godot_env, timeout=900, check_errors=True)
        imported = source / ".godot/imported"
        require(imported.is_dir() and any(imported.iterdir()), "Import produced no imported resource artifacts.")
        self.report["imported_resource_files"] = len(list(imported.iterdir()))
        return source

    def audit_pack(self, pack: Path, prefix: str) -> None:
        report = self.evidence / (prefix + "-resources.json")
        self.command([sys.executable, ROOT / "tools/verify_ios_resources.py", "--pack", pack,
                      "--engine", self.engine, "--report", report, "--project-root", self.source], prefix + "-resource-audit", timeout=900)
        require(read_json(report).get("passed") is True, "Actual exported payload verification did not pass.")

    def export(self) -> tuple[Path, Path]:
        source = self.import_project()
        directory = self.build / "export"
        directory.mkdir()
        self.command([self.engine, "--headless", "--path", source, "--export-debug", self.preset_name,
                      directory / "RuneCast.xcodeproj"], "godot-export", env=self.godot_env, timeout=900, check_errors=True)
        projects = list(directory.glob("*.xcodeproj"))
        packs = list(directory.rglob("*.pck"))
        require(len(projects) == 1 and (projects[0] / "project.pbxproj").is_file(), "Export did not produce exactly one valid Xcode project.")
        require(len(packs) == 1 and packs[0].stat().st_size > 0, "Export did not produce exactly one nonempty Godot payload.")
        self.audit_pack(packs[0], "export")
        self.report.update(xcode_project=str(projects[0]), exported_pack=str(packs[0]), exported_pack_sha256=digest(packs[0]))
        require(not list(directory.rglob("*.ipa")) and not list(directory.rglob("*.xcarchive")), "Unexpected distribution artifact; only project export is permitted.")
        return projects[0], packs[0]

    def build_app(self) -> None:
        project, pack = self.export()
        data = json.loads(self.command(["/usr/bin/xcrun", "xcodebuild", "-project", project, "-list", "-json"], "xcode-project-list", stdout_only=True))
        schemes = data.get("project", {}).get("schemes", [])
        require(len(schemes) == 1, "Exported project has ambiguous schemes; inspect it in Xcode before building.")
        derived = self.build / "DerivedData"
        args = ["/usr/bin/xcrun", "xcodebuild", "-project", project, "-scheme", schemes[0],
                "-configuration", "Debug", "-sdk", "iphoneos", "-destination", "generic/platform=iOS",
                "-derivedDataPath", derived, "-resultBundlePath", self.build / "build.xcresult",
                "DEVELOPMENT_TEAM=" + self.identity["team_id"], "PRODUCT_BUNDLE_IDENTIFIER=" + self.identity["bundle_identifier"],
                "CODE_SIGN_STYLE=Automatic", "CODE_SIGN_IDENTITY=Apple Development", "IPHONEOS_DEPLOYMENT_TARGET=" + MIN_IOS,
                "TARGETED_DEVICE_FAMILY=1", "build"]
        self.command(args, "xcode-debug-build", timeout=1800)
        apps = list((derived / "Build/Products/Debug-iphoneos").glob("*.app"))
        require(len(apps) == 1, "Debug build did not produce exactly one physical-device .app.")
        self.inspect(apps[0], pack)

    def inspect(self, app: Path, exported_pack: Path | None = None) -> None:
        require(under(app, ROOT / "builds/ios") and app.is_dir() and app.suffix == ".app", "Only an existing task-owned .app beneath builds/ios is supported.")
        relative = app.relative_to(ROOT / "builds/ios")
        self.source = ROOT / "builds/ios" / relative.parts[0] / "source"
        require((self.source / "project.godot").is_file(), "The build's staged source is missing; retain it for exact payload verification.")
        require(not any(path.is_symlink() for path in app.rglob("*")), "Unexpected symlinks in built app; inspect manually.")
        info = plistlib.loads((app / "Info.plist").read_bytes())
        validate_info(info, self.identity)
        executable = app / info["CFBundleExecutable"]
        require(executable.is_file() and executable.stat().st_size > 0, "Built app has no executable.")
        archs = self.command(["/usr/bin/xcrun", "lipo", "-archs", executable], "app-architectures")
        require(archs.strip().split() == ["arm64"], "Expected only arm64 for this physical-iPhone development build.")
        self.command(["/usr/bin/codesign", "--verify", "--deep", "--strict", app], "signature-verification")
        details = self.command(["/usr/bin/codesign", "-dvv", app])
        require("TeamIdentifier=" + self.identity["team_id"] in details, "Signed app TeamIdentifier does not match the approved team.")
        require("Authority=Apple Development:" in details or "Authority=iPhone Developer:" in details, "App is not development signed.")
        raw = self.command(["/usr/bin/codesign", "-d", "--entitlements", ":-", app])
        start = raw.find("<?xml")
        require(start >= 0, "Could not read signed XML entitlements.")
        entitlements = plistlib.loads(raw[start:].encode())
        require(entitlements.get("get-task-allow") is True, "Signed app lacks the development debugging entitlement.")
        expected_id = self.identity["team_id"] + "." + self.identity["bundle_identifier"]
        require(entitlements.get("application-identifier") == expected_id, "Signed application identifier differs from approved identity.")
        profile = app / "embedded.mobileprovision"
        require(profile.is_file(), "Development app has no embedded provisioning profile.")
        # Decode in memory only; the profile and certificate bytes never enter evidence.
        provision = plistlib.loads(self.command(["/usr/bin/security", "cms", "-D", "-i", profile], stdout_only=True).encode())
        require(provision.get("Entitlements", {}).get("get-task-allow") is True and provision.get("TeamIdentifier") == [self.identity["team_id"]], "Provisioning profile is not development access for the approved team.")
        require(bool(provision.get("ProvisionedDevices")), "Development profile has no registered devices.")
        expiry = provision.get("ExpirationDate")
        require(isinstance(expiry, datetime) and expiry.replace(tzinfo=timezone.utc) > datetime.now(timezone.utc), "Development profile has expired.")
        packs = list(app.rglob("*.pck"))
        require(len(packs) == 1, "Built app does not contain exactly one Godot payload.")
        if exported_pack:
            require(digest(packs[0]) == digest(exported_pack), "Built payload differs from the audited exported payload.")
        self.audit_pack(packs[0], "app")
        files = [{"path": path.relative_to(app).as_posix(), "size": path.stat().st_size, "sha256": digest(path)}
                 for path in sorted(app.rglob("*")) if path.is_file()]
        write_json(self.evidence / "app-files.json", files)
        self.report.update(app=str(app), app_file_manifest_sha256=digest(self.evidence / "app-files.json"),
                           app_executable_sha256=digest(executable), app_pack_sha256=digest(packs[0]),
                           bundle_identifier=info["CFBundleIdentifier"], short_version=info["CFBundleShortVersionString"],
                           build_number=info["CFBundleVersion"], deployment_target=info["MinimumOSVersion"],
                           development_signed=True, provisioning_expiry_utc=expiry.isoformat() + "Z")
        self.report["signing_team_validation"] = "Verified against built signature and embedded development profile."
        self.provisioned_devices = provision["ProvisionedDevices"]

    def device_command(self, args: list[str], name: str) -> dict:
        # JSON is the supported devicectl scripting interface. Never scrape table output.
        with tempfile.TemporaryDirectory(prefix="runecast-ios-") as folder:
            output = Path(folder) / "result.json"
            self.command(["/usr/bin/xcrun", "devicectl", *args, "--json-output", output], name + "-command", timeout=120)
            data = read_json(output)
        require(data.get("info", {}).get("outcome") == "success" and isinstance(data.get("result"), dict),
                "devicectl JSON outcome is not successful or its schema is unsupported; use Xcode's selected-device workflow.")
        write_json(self.evidence / (name + ".json"), data)
        return data["result"]

    def device(self) -> dict:
        require(self.args.device, "Select the physical iPhone explicitly with --device IDENTIFIER; never pick the first connected device.")
        data = self.device_command(["device", "info", "details", "--device", self.args.device], "selected-device")
        hardware = data.get("hardwareProperties", {})
        properties = data.get("deviceProperties", {})
        connection = data.get("connectionProperties", {})
        require(str(hardware.get("productType", "")).startswith("iPhone"), "Device is not a verified physical iPhone, or JSON schema changed. Inspect in Xcode.")
        require(connection.get("pairingState") == "paired", "Owner must connect, unlock and trust this Mac before deployment.")
        require(properties.get("developerModeStatus") == "enabled", "Owner must enable Developer Mode and unlock the iPhone.")
        require(hardware.get("udid"), "Device response lacks a hardware UDID; use Xcode for this toolchain.")
        self.report["device"] = {"identifier": self.args.device, "udid": hardware["udid"], "model": hardware.get("marketingName", hardware["productType"]),
                                 "product_type": hardware["productType"], "os_version": properties.get("osVersionNumber"),
                                 "paired": True, "developer_mode": "enabled"}
        return hardware

    def deployment(self) -> None:
        require(self.args.manifest, "Pass --manifest output/qa/rc-022/RUN/workflow.json: build/inspect for install; install receipt for launch/diagnostics.")
        manifest = Path(self.args.manifest).expanduser().resolve()
        require(under(manifest, ROOT / "output/qa/rc-022"), "Build manifest must be under output/qa/rc-022.")
        record = read_json(manifest)
        require(record.get("passed") is True and record.get("development_signed") is True, "Manifest does not establish a verified development app.")
        if self.args.action != "install":
            require(record.get("action") == "install" and record.get("installation_verified") is True,
                    "Launch/diagnostics requires the successful install workflow.json for this artifact and selected iPhone; an older same-identity installed app is not build verification.")
        require(record.get("identity") == self.report["identity"], "Manifest identity differs from the approved config.")
        app = Path(record.get("app", "")).resolve()
        self.inspect(app)
        require(self.report["app_file_manifest_sha256"] == record.get("app_file_manifest_sha256"), "App contents changed after its verified manifest was written.")
        hardware = self.device()
        if self.args.action != "install":
            require(record.get("device", {}).get("udid") == hardware["udid"], "Installation receipt belongs to a different iPhone.")
        require(hardware["udid"] in self.provisioned_devices, "Selected iPhone is absent from the existing provisioning profile. Owner must resolve signing in Xcode; app data will be preserved.")
        bundle = self.identity["bundle_identifier"]
        if self.args.action == "install":
            result = self.device_command(["device", "install", "app", "--device", self.args.device, str(app)], "install")
            installed = result.get("installedApplications", [])
            require(any(item.get("bundleID", item.get("bundleIdentifier")) == bundle for item in installed),
                    "Installation result did not identify the approved app; inspect it in Xcode before claiming installation.")
            self.report["installation_verified"] = True
        elif self.args.action == "launch":
            result = self.device_command(["device", "process", "launch", "--device", self.args.device, bundle], "launch")
            process = result.get("process", {})
            require(isinstance(process.get("processIdentifier"), int) and process["processIdentifier"] > 0,
                    "Launch returned no valid app PID; physical launch is not verified.")
            require("/" + app.name + "/" in process.get("executable", ""), "Launch result did not identify this app executable.")
            self.report["launch_pid"] = process["processIdentifier"]
            self.report["launch_verification"] = "OS reported app process for the artifact previously installed through this workflow; ongoing gameplay acceptance still requires observations."
        else:
            help_text = self.command(["/usr/bin/xcrun", "devicectl", "device", "process", "launch", "--help"], "launch-help")
            require("--console" in help_text, "This devicectl has no app console capture. In Xcode select this iPhone, run the Debug scheme and retain only RuneCast's debug console.")
            command = shlex.join(["xcrun", "devicectl", "device", "process", "launch", "--console", "--device", self.args.device, bundle])
            command = "DEVELOPER_DIR=" + shlex.quote(self.report["selected_developer_dir"]) + " " + command
            output = self.evidence / "app-console.txt"
            guide = "Run in a separate Terminal while testing (app-scoped stdout/stderr only):\n" + command + " 2>&1 | tee " + shlex.quote(str(output)) + "\nStop capture with Ctrl-C after recording observations. If already running, use Xcode's Attach to Process for RuneCast. Do not use devicectl diagnose, which gathers broad device/host diagnostics.\n"
            (self.evidence / "diagnostics-command.txt").write_text(guide, encoding="utf-8")
            print(guide)
            self.report["diagnostics"] = "Precise app-console command prepared; capture not executed by this action."

    def run(self) -> None:
        if self.args.action == "devices":
            self.mac()
            self.device_command(["list", "devices"], "devices")
            return
        self.preflight()
        if self.args.action == "preflight":
            if self.args.device:
                self.device()
        elif self.args.action == "import":
            self.import_project()
        elif self.args.action == "export":
            self.export()
        elif self.args.action == "build":
            self.build_app()
        elif self.args.action == "inspect":
            require(self.args.app, "Pass --app builds/ios/RUN/DerivedData/Build/Products/Debug-iphoneos/RuneCast.app.")
            self.inspect(Path(self.args.app).expanduser().resolve())
        else:
            self.deployment()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("preflight", "import", "export", "build", "inspect", "devices", "install", "launch", "diagnostics"))
    parser.add_argument("--godot", help="Absolute macOS Standard editor executable; no Windows default")
    parser.add_argument("--templates", help="Directory with matching version.txt and ios.zip")
    parser.add_argument("--identity", help="External owner-approved JSON; no credentials")
    parser.add_argument("--developer-dir", help="Process-only Xcode Contents/Developer selection")
    parser.add_argument("--device", help="Explicit physical iPhone UDID/CoreDevice identifier")
    parser.add_argument("--app", help="Task-owned .app for inspect")
    parser.add_argument("--manifest", help="Build/inspect workflow.json for install; install workflow.json for launch/diagnostics")
    args = parser.parse_args(argv)
    workflow = None
    try:
        workflow = Workflow(args)
        workflow.run()
        workflow.report["passed"] = True
        print(f"Completed {args.action}. Evidence: {workflow.evidence}")
        return 0
    except (WorkflowError, OSError, ValueError, zipfile.BadZipFile, configparser.Error) as error:
        if workflow:
            workflow.report["failure"] = str(error)
        print(f"iOS workflow stopped: {error}", file=sys.stderr)
        if workflow:
            print(f"Evidence: {workflow.evidence}", file=sys.stderr)
        return 2
    finally:
        if workflow:
            write_json(workflow.evidence / "workflow.json", workflow.report)


if __name__ == "__main__":
    raise SystemExit(main())
