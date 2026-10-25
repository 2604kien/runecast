"""RC-031 real battle/item room/restart and failed acquisition campaigns."""
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
    args = parser.parse_args()
    output = ROOT / 'output/qa/rc-031/process' / uuid.uuid4().hex[:10]
    output.mkdir(parents=True)
    env = os.environ.copy()
    for key in ('APPDATA', 'LOCALAPPDATA'):
        path = output / key.lower(); path.mkdir(); env[key] = str(path)
    normal = ['new', 'win', 'recovery_entry', 'recovery_before', 'shop_entry', 'upgrade', 'relic', 'remove', 'leave', 'tithe_entry', 'tithe', 'second_shop_entry', 'second_upgrade', 'second_relic', 'second_leave', 'recovery2_entry', 'recovery_after', 'battle_entry', 'replay', 'battle_win', 'desk_entry', 'desk_upgrade', 'reliquary_entry', 'reliquary_take', 'settled']
    scenarios = {'heart-mender': (15, normal, '', ''), 'mender-heart': (8, normal, '', '')}
    for action in ('upgrade', 'relic'):
        for point in ('write', 'flush', 'close', 'backup', 'replace'):
            scenarios[f'failure-{action}-{point}'] = (15, normal[:normal.index(action)] + ['fail', 'retry', 'settled_failure'], action, point)
    report = {'checks': 0, 'failures': 0, 'launches': 0, 'stages': []}
    for scenario, (seed, stages, action, point) in scenarios.items():
        if args.only and args.only not in scenario: continue
        folder = output / scenario; folder.mkdir()
        for stage in stages:
            command = [str(ENGINE), '--headless', '--path', str(ROOT), '--audio-driver', 'Dummy', '--log-file', str(folder / (stage + '.log')), '--script', 'res://tests/rc031_process_runner.gd', '--', '--save-root=' + str(folder), '--stage=' + stage, '--seed=' + str(seed), '--action=' + action, '--point=' + point]
            result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=120)
            console = result.stdout + result.stderr
            (folder / (stage + '-console.txt')).write_text(console, encoding='utf-8')
            path = folder / (stage + '.json')
            evidence = json.loads(path.read_text()) if path.exists() else {'checks': 0, 'failures': 1}
            evidence.update(scenario=scenario, stage=stage, exit_code=result.returncode)
            if re.search(r'(?m)^(?:SCRIPT )?ERROR:', console): evidence['failures'] = max(evidence['failures'], 1)
            report['checks'] += evidence['checks']; report['failures'] += max(evidence['failures'], int(result.returncode != 0)); report['launches'] += 1; report['stages'].append(evidence)
            print(f"{scenario}/{stage}: {evidence['checks']} checks, {evidence['failures']} failures", flush=True)
            if result.returncode or evidence['failures']:
                print(console, flush=True); break
    (output / 'results.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f"{report['checks']} checks, {report['failures']} failures across {report['launches']} launches; {output}", flush=True)
    return int(report['failures'] != 0)

if __name__ == '__main__': raise SystemExit(main())
