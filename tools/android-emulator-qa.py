#!/usr/bin/env python3
"""Record explicit ADB input/captures on the owned RuneCast_API36 emulator.

This helper never installs/uninstalls packages, clears data, accesses a physical
device, or collects broad logcat. A successful input command is not a UI pass.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import time


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output/qa/rc-021/emulator"
PACKAGE = "com.example.runecast"
EXPECTED_AVD = "RuneCast_API36"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def timestamp() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="milliseconds")


class Recorder:
    def __init__(self, adb: Path, serial: str):
        self.adb = adb.resolve()
        self.serial = serial
        if not re.fullmatch(r"emulator-\d+", serial):
            raise ValueError("Only an explicit emulator-NNNN serial is allowed")
        if not self.adb.is_file():
            raise ValueError(f"ADB executable not found: {self.adb}")

    def run(self, *arguments: str, timeout: float = 30) -> bytes:
        result = subprocess.run(
            [str(self.adb), "-s", self.serial, *arguments],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=timeout, check=False,
        )
        if result.returncode:
            detail = result.stderr.decode("utf-8", "replace").strip()
            raise RuntimeError(f"ADB exited {result.returncode}: {detail[:2000]}")
        return result.stdout

    def guard(self) -> dict:
        response = self.run("emu", "avd", "name").decode("utf-8", "replace")
        lines = [line.strip() for line in response.splitlines() if line.strip()]
        if lines != [EXPECTED_AVD, "OK"]:
            raise RuntimeError(f"Emulator guard rejected AVD response: {response[:300]!r}")
        path_response = self.run("emu", "avd", "path").decode("utf-8", "replace")
        path_lines = [line.strip() for line in path_response.splitlines() if line.strip()]
        if len(path_lines) != 2 or path_lines[1] != "OK":
            raise RuntimeError(f"Emulator guard rejected AVD path response: {path_response[:300]!r}")
        reported = Path(path_lines[0])
        if not reported.is_absolute():
            raise RuntimeError("Emulator guard requires an absolute AVD path")
        actual_path = reported.resolve(strict=True)
        expected_path = (ROOT / ".tools/android/avd" / (EXPECTED_AVD + ".avd")).resolve(strict=True)
        if not actual_path.is_dir() or str(actual_path).casefold() != str(expected_path).casefold():
            raise RuntimeError(f"Emulator guard rejected AVD directory: {actual_path}")
        return {"serial": self.serial, "avd": EXPECTED_AVD, "avd_path": str(actual_path)}

    @staticmethod
    def save_evidence(folder: str, name: str, suffix: str, data: bytes) -> dict:
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,79}", name):
            raise ValueError("Evidence name must be 1-80 letters/digits/dot/underscore/hyphen")
        destination = OUTPUT / folder
        destination.mkdir(parents=True, exist_ok=True)
        path = destination / (name + suffix)
        counter = 1
        while path.exists():
            path = destination / f"{name}-{counter:02d}{suffix}"
            counter += 1
        with path.open("xb") as handle:
            handle.write(data)
        return {"path": str(path), "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}

    def action(self, action: dict) -> dict:
        started = timestamp()
        record = {"timestamp_utc": started, "source": "automated_adb", "args": action}
        try:
            kind = action.get("action")
            record["target"] = self.guard()
            if kind == "capture":
                name = action["name"]
                if not isinstance(name, str):
                    raise ValueError("Capture name must be a string")
                data = self.run("exec-out", "screencap", "-p")
                if not data.startswith(PNG_SIGNATURE):
                    raise RuntimeError("screencap did not return a PNG")
                result = self.save_evidence("screenshots", name, ".png", data)
            elif kind == "tap":
                values = self.coordinates(action, "x", "y")
                self.run("shell", "input", "tap", *values)
                result = {"input_sent": True, "ui_result": "requires_observation"}
            elif kind == "swipe":
                values = self.coordinates(action, "x", "y", "x2", "y2")
                duration = action.get("duration", 350)
                if type(duration) is not int or not 1 <= duration <= 15000:
                    raise ValueError("Swipe duration must be an integer from 1 to 15000 ms")
                self.run("shell", "input", "swipe", *values, str(duration))
                result = {"input_sent": True, "ui_result": "requires_observation"}
            elif kind == "key":
                key = str(action["keycode"])
                if not re.fullmatch(r"KEYCODE_[A-Z0-9_]+|\d{1,3}", key):
                    raise ValueError("Key must be KEYCODE_NAME or a numeric Android keycode")
                self.run("shell", "input", "keyevent", key)
                result = {"input_sent": True, "ui_result": "requires_observation"}
            elif kind == "wait":
                seconds = action["seconds"]
                if type(seconds) not in (int, float) or not 0 <= seconds <= 15:
                    raise ValueError("Wait must be from 0 to 15 seconds")
                start = time.monotonic()
                time.sleep(seconds)
                result = {"elapsed_seconds": round(time.monotonic() - start, 3)}
            elif kind == "settings":
                result = self.settings(action.get("name", "settings"))
            else:
                raise ValueError(f"Unsupported action: {kind!r}")
            record.update(status="completed", result=result)
            return record
        except Exception as error:
            record.update(status="failed", result={"error": str(error)})
            raise
        finally:
            record["finished_utc"] = timestamp()
            OUTPUT.mkdir(parents=True, exist_ok=True)
            with (OUTPUT / "actions.jsonl").open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(record, ensure_ascii=False) + "\n")

    @staticmethod
    def coordinates(action: dict, *names: str) -> list[str]:
        values = [action[name] for name in names]
        if any(type(value) is not int or not 0 <= value <= 16384 for value in values):
            raise ValueError("Coordinates must be integer pixels from 0 to 16384")
        return [str(value) for value in values]

    def settings(self, name: str) -> dict:
        # run-as constrains both discovery and reads to this debuggable app.
        app_directory = self.run("shell", "run-as", PACKAGE, "pwd").decode().strip()
        if not re.fullmatch(r"/data/(?:user/\d+|data)/com\.example\.runecast", app_directory):
            raise RuntimeError("run-as returned an unexpected app directory")
        discovered = self.run(
            "shell", "run-as", PACKAGE, "find", ".", "-type", "f", "-name", "settings.cfg"
        ).decode("utf-8", "replace").splitlines()
        files = []
        for index, relative in enumerate(discovered):
            relative = relative.strip()
            path = PurePosixPath(relative)
            if path.is_absolute() or ".." in path.parts or path.name != "settings.cfg":
                raise RuntimeError("Rejected unexpected settings discovery result")
            data = self.run("exec-out", "run-as", PACKAGE, "cat", "./" + str(path))
            if len(data) > 131072:
                raise RuntimeError("settings.cfg exceeds the 128 KiB evidence limit")
            evidence = self.save_evidence("settings", f"{name}-{index + 1}", ".cfg", data)
            files.append({"app_relative_path": str(path), **evidence})
        return {"app_directory": app_directory, "files": files, "file_count": len(files)}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", type=Path, default=ROOT / ".tools/android/sdk/platform-tools/adb.exe")
    parser.add_argument("--serial", default="emulator-5554")
    commands = parser.add_subparsers(dest="command", required=True)
    capture = commands.add_parser("capture", help="Save a binary PNG screenshot")
    capture.add_argument("name")
    tap = commands.add_parser("tap")
    tap.add_argument("x", type=int)
    tap.add_argument("y", type=int)
    swipe = commands.add_parser("swipe")
    for coordinate in ("x", "y", "x2", "y2"):
        swipe.add_argument(coordinate, type=int)
    swipe.add_argument("duration", type=int, nargs="?", default=350)
    key = commands.add_parser("key")
    key.add_argument("keycode")
    pause = commands.add_parser("wait")
    pause.add_argument("seconds", type=float)
    settings = commands.add_parser("settings", help="Capture only this app's settings.cfg")
    settings.add_argument("name", nargs="?", default="settings")
    sequence = commands.add_parser("sequence", help='JSON list, or {"actions": [...]}')
    sequence.add_argument("file", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        recorder = Recorder(args.adb, args.serial)
        if args.command == "sequence":
            document = json.loads(args.file.read_text(encoding="utf-8-sig"))
            actions = document.get("actions") if isinstance(document, dict) else document
            if not isinstance(actions, list) or not actions or len(actions) > 100:
                raise ValueError("Sequence must contain 1-100 action objects")
        else:
            action = {key: value for key, value in vars(args).items() if key not in ("adb", "serial", "command")}
            action["action"] = args.command
            actions = [action]
        for action in actions:
            if not isinstance(action, dict):
                raise ValueError("Each action must be a JSON object")
            print(json.dumps(recorder.action(action), ensure_ascii=False), flush=True)
        return 0
    except (ValueError, OSError, RuntimeError, KeyError, subprocess.TimeoutExpired) as error:
        print(f"Emulator QA stopped: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
