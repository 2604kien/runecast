"""RC-032 Store purchase write failures: real same-process Retry versus fresh restart."""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import uuid

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--only', default='')
    parser.add_argument('--output-root', type=Path, default=ROOT / 'output/qa/rc-032-store/process')
    args = parser.parse_args()
    output = args.output_root.resolve() / uuid.uuid4().hex[:10]
    output.mkdir(parents=True)
    report = {'checks': 0, 'failures': 0, 'launches': 0, 'stages': []}
    for operation in ('rune-first', 'relic-first', 'rune-second', 'relic-second'):
        for point in ('write', 'flush', 'close', 'backup', 'replace'):
            for mode in ('retry', 'restart'):
                scenario = f'{operation}-{point}-{mode}'
                if args.only and args.only not in scenario:
                    continue
                folder = output / scenario
                folder.mkdir()
                env = os.environ.copy()
                for key in ('APPDATA', 'LOCALAPPDATA'):
                    path = folder / key.lower()
                    path.mkdir()
                    env[key] = str(path)
                for stage in ('prepare', 'fail', 'restart', 'damage', 'recover', 'recovered'):
                    command = [str(ENGINE), '--headless', '--path', str(ROOT), '--audio-driver', 'Dummy', '--log-file', str(folder / (stage + '.log')), '--script', 'res://tests/rc032_store_process_runner.gd', '--', '--save-root=' + str(folder), '--stage=' + stage, '--operation=' + operation, '--point=' + point, '--mode=' + mode]
                    result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=120)
                    console = result.stdout + result.stderr
                    (folder / (stage + '-console.txt')).write_text(console, encoding='utf-8')
                    evidence_path = folder / (stage + '.json')
                    evidence = json.loads(evidence_path.read_text()) if evidence_path.exists() else {'checks': 0, 'failures': 1}
                    evidence.update(scenario=scenario, stage=stage, exit_code=result.returncode)
                    if re.search(r'(?m)^(?:SCRIPT )?ERROR:', console):
                        evidence['failures'] = max(evidence['failures'], 1)
                    report['checks'] += evidence['checks']
                    report['failures'] += max(evidence['failures'], int(result.returncode != 0))
                    report['launches'] += 1
                    report['stages'].append(evidence)
                    print(f"{scenario}/{stage}: {evidence['checks']} checks, {evidence['failures']} failures", flush=True)
                    if result.returncode or evidence['failures']:
                        print(console, flush=True)
                        break
    (output / 'results.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f"{report['checks']} checks, {report['failures']} failures across {report['launches']} launches; {output}", flush=True)
    return int(report['failures'] != 0)

if __name__ == '__main__':
    raise SystemExit(main())
