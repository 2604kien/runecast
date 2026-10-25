"""RC-030 fresh-process service, failure/Retry and genuine v1/v2 migration checks."""
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
    parser.add_argument("--output", type=Path, default=ROOT / "output/qa/rc-030/process")
    parser.add_argument("--only", default="", help="Optional scenario substring for a focused rerun.")
    args = parser.parse_args()
    output = args.output.resolve() / uuid.uuid4().hex[:10]
    output.mkdir(parents=True)
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA"):
        folder = output / key.lower()
        folder.mkdir()
        env[key] = str(folder)
    scenarios = {}
    ordinary = ["new", "win", "entry", "resolve", "next", "replay", "next_win", "second_entry", "second_resolve", "shop", "settled"]
    for variant in ("recovery", "satchel", "tithe", "reliquary", "desk"):
        scenarios["ordinary-" + variant] = (variant, ordinary)
    for variant in ("recovery", "tithe"):
        for action in ("entry", "resolve"):
            for point in ("write", "flush", "close", "backup", "replace"):
                index = ordinary.index(action)
                scenarios[f"failure-{action}-{point}-{variant}"] = (variant, ordinary[:index] + ["fail", "retry"] + ordinary[index + 1:])
    migration = ["legacy", "migration_fail", "migrate", "migration_restart", "damage", "recover", "recovered"]
    for variant in ("production-v1", "reward-v1", "production-v2", "active-shop-v2", "completed-shop-v2", "replay-shop-v2", "pending-reward-v2"):
        scenarios["migration-" + variant] = (variant, migration + ["legacy_continue", "legacy_continued"])
    report = {"output": str(output), "checks": 0, "failures": 0, "stages": []}
    for scenario, (variant, stages) in scenarios.items():
        if args.only and args.only not in scenario:
            continue
        folder = output / scenario
        folder.mkdir()
        for stage in stages:
            command = [str(ENGINE), "--headless", "--path", str(ROOT), "--audio-driver", "Dummy", "--log-file", str(folder / (stage + ".log")), "--script", "res://tests/service_process_runner.gd", "--", "--save-root=" + str(folder), "--scenario=" + scenario, "--variant=" + variant, "--stage=" + stage]
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
