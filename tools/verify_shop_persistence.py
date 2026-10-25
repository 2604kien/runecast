"""RC-029 stages use separate pinned Godot OS processes and isolated saves."""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import uuid

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / ".tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "output/qa/rc-029/process")
    args = parser.parse_args()
    output = args.output.resolve() / uuid.uuid4().hex[:10]
    output.mkdir(parents=True)
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA"):
        folder = output / key.lower()
        folder.mkdir()
        env[key] = str(folder)
    actions = ["entry", "purchase", "remove", "leave"]
    scenarios = {"ordinary": ["new", "win", *actions, "next", "replay"]}
    for action, points in [("purchase", ["write", "flush", "close", "backup", "replace"]),
                           ("entry", ["replace"]), ("remove", ["replace"]), ("leave", ["replace"])]:
        for point in points:
            index = actions.index(action)
            scenarios[f"{action}_{point}"] = ["new", "win", *actions[:index], "fail", "retry", *actions[index + 1:], "next", "replay"]
    report = {"output": str(output), "checks": 0, "failures": 0, "stages": []}
    for scenario, stages in scenarios.items():
        folder = output / scenario
        folder.mkdir()
        for stage in stages:
            command = [str(ENGINE), "--headless", "--path", str(ROOT), "--audio-driver", "Dummy", "--log-file", str(folder / (stage + ".log")), "--script", "res://tests/shop_process_runner.gd", "--", "--save-root=" + str(folder), "--scenario=" + scenario, "--stage=" + stage]
            result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120)
            console = result.stdout + result.stderr
            (folder / (stage + "-console.txt")).write_text(console, encoding="utf-8")
            path = folder / (stage + ".json")
            evidence = json.loads(path.read_text()) if path.exists() else {"checks": 0, "failures": 1, "error": console}
            evidence["exit_code"] = result.returncode
            if re.search(r"(?m)^(?:SCRIPT )?ERROR:", console):
                evidence["failures"] = max(evidence["failures"], 1)
                evidence["engine_error"] = True
            report["stages"].append(evidence)
            report["checks"] += evidence["checks"]
            report["failures"] += max(evidence["failures"], int(result.returncode != 0))
            print(f"{scenario}/{stage}: {evidence['checks']} checks, {evidence['failures']} failures", flush=True)
            if result.returncode or evidence["failures"]:
                print(console, flush=True)
                break
    (output / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"{report['checks']} checks, {report['failures']} failures; evidence {output}", flush=True)
    return int(report["failures"] != 0)


if __name__ == "__main__":
    raise SystemExit(main())
