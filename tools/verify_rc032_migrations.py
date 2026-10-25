"""Fresh-process RC-032 migration/recovery against genuine v1/v2/v3/v4 bytes."""
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
    parser.add_argument('--output', type=Path, default=ROOT / 'output/qa/rc-032/migrations')
    args = parser.parse_args()
    output = args.output.resolve() / uuid.uuid4().hex[:10]
    output.mkdir(parents=True)
    env = os.environ.copy()
    for key in ('APPDATA', 'LOCALAPPDATA'):
        path = output / key.lower()
        path.mkdir()
        env[key] = str(path)
    report = {'checks': 0, 'failures': 0, 'launches': 0, 'stages': []}
    stages = ['import', 'fail-write', 'fail-flush', 'fail-close', 'fail-backup', 'fail-replace', 'migrate', 'restart', 'damage', 'recover', 'recovered']
    fixtures = sorted(p for family in ('rc028', 'rc029', 'rc030', 'rc031') for p in (ROOT / 'tests/fixtures' / family).glob('*-v?.json') if not p.name.startswith('origins'))
    for fixture in fixtures:
        if args.only and args.only not in fixture.stem:
            continue
        folder = output / fixture.stem
        folder.mkdir()
        for stage in stages:
            command = [str(ENGINE), '--headless', '--path', str(ROOT), '--audio-driver', 'Dummy', '--log-file', str(folder / (stage + '.log')), '--script', 'res://tests/rc032_migration_runner.gd', '--', '--save-root=' + str(folder), '--fixture=' + fixture.stem, '--stage=' + stage]
            result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=120)
            console = result.stdout + result.stderr
            (folder / (stage + '-console.txt')).write_text(console, encoding='utf-8')
            path = folder / (stage + '.json')
            evidence = json.loads(path.read_text()) if path.exists() else {'checks': 0, 'failures': 1}
            evidence.update(fixture=fixture.stem, stage=stage, exit_code=result.returncode)
            if re.search(r'(?m)^(?:SCRIPT )?ERROR:', console):
                evidence['failures'] = max(evidence['failures'], 1)
                evidence['engine_error'] = True
            report['checks'] += evidence['checks']
            report['failures'] += max(evidence['failures'], int(result.returncode != 0))
            report['launches'] += 1
            report['stages'].append(evidence)
            print(f"{fixture.stem}/{stage}: {evidence['checks']} checks, {evidence['failures']} failures", flush=True)
            if result.returncode or evidence['failures']:
                print(console, flush=True)
                break
    (output / 'results.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f"{report['checks']} checks, {report['failures']} failures across {report['launches']} launches; {output}", flush=True)
    return int(report['failures'] != 0)

if __name__ == '__main__':
    raise SystemExit(main())
