"""Run existing RC-031-relevant suites with isolated data and redirected evidence."""
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
SUITES = {
    'core': 'test_runner', 'ui': 'ui_smoke', 'shell': 'application_shell_tests',
    'shop-model': 'shop_model_runner', 'shop-shell': 'shop_shell_runner',
    'service-model': 'service_model_runner', 'service-shell': 'service_shell_runner',
    'save-model': 'save_model_runner', 'local-save': 'local_save_runner',
    'persistence-audio': 'persistence_audio_runner', 'persistence-shell': 'persistence_shell_runner',
    'reward-state': 'reward_state_runner', 'reward-integration': 'reward_integration_runner',
    'reward-audio': 'reward_audio_runner', 'collection-data': 'collection_data_runner',
    'collection-shell': 'collection_shell_runner', 'encounter': 'encounter_integration_runner',
    'audio-settings': 'audio_settings_runner', 'audio-playback': 'audio_playback_runner',
    'shared-menu': 'shared_menu_capture', 'reference': 'ui_reference_match_capture',
}

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--only', default=','.join(k for k in SUITES if k not in ('shared-menu', 'reference')))
    parser.add_argument('--render', action='store_true')
    args = parser.parse_args()
    output = ROOT / 'output/qa/rc-031/regression' / uuid.uuid4().hex[:10]
    output.mkdir(parents=True)
    env = os.environ.copy()
    for key in ('APPDATA', 'LOCALAPPDATA'):
        path = output / key.lower()
        path.mkdir()
        env[key] = str(path)
    report = {'checks': 0, 'failures': 0, 'suites': []}
    for key in args.only.split(','):
        source = ROOT / ('tests/' + SUITES[key] + '.gd')
        folder = output / key
        folder.mkdir()
        runner = folder / 'runner.gd'
        evidence_prefix = 'res://' + folder.relative_to(ROOT).as_posix() + '/evidence/'
        runner.write_text(source.read_text(encoding='utf-8-sig').replace('res://output/qa/', evidence_prefix), encoding='utf-8')
        command = [str(ENGINE), '--path', str(ROOT), '--audio-driver', 'Dummy', '--log-file', str(folder / 'engine.log'), '--script', 'res://' + runner.relative_to(ROOT).as_posix()]
        if not args.render:
            command.insert(1, '--headless')
        command += ['--', '--qa-output=' + evidence_prefix + 'shell']
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=240)
        console = result.stdout + result.stderr
        (folder / 'console.txt').write_text(console, encoding='utf-8')
        summary_text = re.sub(r'RC-\d+', 'RC', console)
        matches = re.findall(r'(\d+)[^:\n\d]*checks,\s*(\d+)\s+failures', summary_text)
        if not matches:
            matches = re.findall(r'checks:\s*(\d+);\s*failures:\s*(\d+)', console)
        checks, failures = map(int, matches[-1]) if matches else (0, 1)
        if not matches:
            for saved in folder.rglob('results*.json'):
                measured = json.loads(saved.read_text(encoding='utf-8-sig'))
                if isinstance(measured.get('checks'), int) and isinstance(measured.get('failures'), int):
                    checks, failures = measured['checks'], measured['failures']
                    break
        errors = [line for line in console.splitlines() if re.match(r'^(?:SCRIPT )?ERROR:', line)]
        item = {'suite': key, 'checks': checks, 'failures': failures, 'exit_code': result.returncode, 'engine_errors': errors, 'path': str(folder)}
        report['suites'].append(item)
        report['checks'] += checks
        report['failures'] += max(failures, int(result.returncode != 0 or bool(errors)))
        print(f'{key}: {checks} checks, {failures} failures, exit {result.returncode}, {len(errors)} errors', flush=True)
        if failures or errors:
            print('\n'.join(errors[:12]), flush=True)
    (output / 'results.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f"{report['checks']} checks, {report['failures']} failures; {output}", flush=True)
    return int(report['failures'] != 0)

if __name__ == '__main__':
    raise SystemExit(main())
