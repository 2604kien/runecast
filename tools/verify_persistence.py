"""RC-028: every stage uses a separate pinned Godot OS process and isolated files."""
from __future__ import annotations
import argparse
import json
import os
import re
from pathlib import Path
import subprocess
import uuid

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'output/qa/rc-028/process')
    args = parser.parse_args()
    output = args.output.resolve() / uuid.uuid4().hex[:10]
    output.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    env.update(APPDATA=str(output / 'appdata'), LOCALAPPDATA=str(output / 'localappdata'))
    Path(env['APPDATA']).mkdir()
    Path(env['LOCALAPPDATA']).mkdir()
    stages = ['new', 'route', 'interrupt', 'win', 'result', 'first_claim', 'second_claim', 'settled']
    scenarios = {'production': ['new', 'route', 'new_again', 'profile', 'retire_profile', 'profile_only'],
                 'gold_first': stages, 'rune_first': stages, 'skip': stages,
                 'unlock': stages + ['new_again', 'profile', 'retire_profile', 'profile_only'],
                 'exhausted': stages, 'guardian': stages,
                 'defeat': ['new', 'route', 'interrupt', 'defeat', 'defeated', 'terminal']}
    for point in ('write', 'flush', 'close', 'backup', 'replace'):
        scenarios['failure_' + point] = ['new', 'route', 'interrupt', 'win', 'result', 'fail_claim', 'retry_claim', 'claim_gold', 'settled']
    report = {'output': str(output), 'stages': [], 'checks': 0, 'failures': 0}
    for scenario, actions in scenarios.items():
        folder = output / scenario
        folder.mkdir()
        for stage in actions:
            command = [str(ENGINE), '--headless', '--path', str(ROOT), '--log-file',
                       str(folder / (stage + '.log')), '--script', 'res://tests/persistence_process_runner.gd',
                       '--', '--save-root=' + str(folder), '--scenario=' + scenario, '--stage=' + stage]
            result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=120)
            (folder / (stage + '-console.txt')).write_text(result.stdout + result.stderr, encoding='utf-8')
            path = folder / (stage + '.json')
            evidence = json.loads(path.read_text()) if path.exists() else {'checks': 0, 'failures': 1, 'error': result.stdout + result.stderr}
            evidence['exit_code'] = result.returncode
            if re.search(r'(?m)^(?:SCRIPT )?ERROR:', result.stdout + result.stderr):
                evidence['failures'] = max(evidence['failures'], 1)
                evidence['engine_error'] = True
            report['stages'].append(evidence)
            report['checks'] += evidence['checks']
            report['failures'] += max(evidence['failures'], int(result.returncode != 0))
            print(f"{scenario}/{stage}: {evidence['checks']} checks, {evidence['failures']} failures", flush=True)
            if result.returncode or evidence['failures']:
                print(result.stdout + result.stderr, flush=True)
                break
    (output / 'results.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f"{report['checks']} checks, {report['failures']} failures; evidence {output}", flush=True)
    return int(report['failures'] != 0)


if __name__ == '__main__':
    raise SystemExit(main())
