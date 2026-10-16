"""RC-013 focused source/import/layout/packaging audit. Never uses Git."""
from pathlib import Path
import argparse
import csv
import hashlib
import json
import re
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
QA = ROOT / 'output/qa/rc-013'
MENU_QA = QA / 'menu-button-revert'
MENU_ART = ROOT / 'output/art/rc-013/menu-button-revert'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--report', default='output/qa/rc-013/validation-report.json', help='Write the current audit separately from retained historical reports')
args = parser.parse_args()
errors = []
counts = {}


def check(ok, message, group):
    counts[group] = counts.get(group, 0) + 1
    if not ok:
        errors.append(message)


def read(path):
    return (ROOT / path).read_text(encoding='utf-8-sig')


def data(path):
    return json.loads(read(path))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None


for row in data('output/qa/rc-013/protected-baseline.json'):
    check(sha(ROOT / row['path']) == row['sha256'], 'Protected file changed: ' + row['path'], 'preservation')

source_report = data('output/qa/rc-013/source-validation.json')
check(source_report.get('pass') is True or source_report.get('result') == 'PASS', 'Source validation failed', 'sources')
mapping = data('source-assets/ui/source-export-map.json')
retired_runtime_files = ['assets/ui/frames/pile.png'] + [
    'assets/ui/states/' + name + '.svg' for name in
    ['eligible', 'focused', 'invalid', 'powered', 'protected', 'selected', 'unavailable', 'upgrade']
]
for retired in retired_runtime_files:
    check(not (ROOT / retired).exists() and not (ROOT / (retired + '.import')).exists(),
          'Unused runtime resource was recreated: ' + retired, 'retired_exports')
    check(not any(row['runtime'] == retired for row in mapping['exports']),
          'Retired runtime export is still advertised: ' + retired, 'retired_exports')
for row in mapping['exports']:
    path = ROOT / row['runtime']
    check(sha(path) == row['sha256'], 'Export differs from provenance: ' + row['runtime'], 'exports')
    check((ROOT / row['master']).is_file(), 'Source master absent: ' + row['runtime'], 'sources')
    recipe = path.with_name(path.name + '.import')
    check(recipe.is_file(), 'Missing import recipe: ' + row['runtime'], 'imports')
    if recipe.is_file():
        settings = recipe.read_text(encoding='utf-8-sig')
        check('compress/mode=0' in settings and 'mipmaps/generate=false' in settings,
              'Lossless/no-mipmap recipe missing: ' + row['runtime'], 'imports')
    if path.suffix == '.png':
        with Image.open(path) as img:
            check(list(img.size) == row['size'] and img.mode == 'RGBA', 'Wrong dimensions/alpha: ' + row['runtime'], 'exports')

# The latest Menu correction staged the complete current resource set.
# Recreate this strict identity input with the current Menu preview wrapper.
staged = MENU_QA / 'preview-project'
for folder in ['assets/ui', 'assets/icons', 'assets/fonts', 'scenes/ui/theme']:
    for path in (ROOT / folder).rglob('*'):
        if path.suffix not in ['.png', '.svg', '.ttf', '.gd', '.tres']:
            continue
        rel = path.relative_to(ROOT)
        check(sha(path) == sha(staged / rel), 'Staged resource differs: ' + str(rel), 'staged_identity')

for path in list((ROOT / 'assets/ui').rglob('*.tres')) + list((ROOT / 'scenes/ui/theme').glob('*.gd')):
    text = path.read_text(encoding='utf-8-sig')
    for ref in re.findall(r'(?:path=|preload\(|load\()"res://([^"\n]+)"', text):
        if Path(ref).suffix:
            check((ROOT / ref).is_file(), 'Resource path missing: ' + ref, 'dependencies')
    check('res://scripts/core/' not in text and 'res://scripts/ui/main.gd' not in text,
          'Display component depends on gameplay: ' + path.name, 'boundaries')

theme = read('assets/ui/rune_cast_theme.tres')
for variation in ['RCTitle', 'RCBody', 'RCLocation', 'RCPointed', 'RCSecondaryLive', 'RCCardLive', 'RCSocket', 'RCDialog', 'RCForecast', 'RCHealth', 'RCEnergy']:
    check(variation + '/base_type' in theme, 'Theme variation missing: ' + variation, 'theme')
for relative, weight in [('display/title', 700), ('ui/labels', 600), ('ui/location', 500)]:
    font = read('assets/fonts/' + relative + '.tres')
    check(re.search(r'"weight":\s*' + str(weight), font) is not None and re.search(r'"width":\s*100', font) is not None,
          'Wrong font axes: ' + relative, 'fonts')

render = data('output/qa/rc-013/godot-render-results.json')
check(render['result'] == 'PASS' and not render['errors'], 'Godot layout/input report failed', 'renders')
menu_render = data('output/qa/rc-013/menu-button-revert/godot-render-results.json')
check(menu_render['result'] == 'PASS' and not menu_render['errors'], 'Current retained Menu layout/input report failed', 'renders')
menu_modes = {'menu-open', 'menu-locked'}
check(len(menu_render['sheets']) == 6 and all(sheet['mode'] in menu_modes for sheet in menu_render['sheets']),
      'Current Menu report must contain both states at three sizes', 'renders')
current_sheets = [(sheet, ROOT / 'output/art/rc-013') for sheet in render['sheets'] if sheet['mode'] not in menu_modes]
current_sheets += [(sheet, MENU_ART) for sheet in menu_render['sheets']]
imported = {row['path'].removeprefix('res://'): row for row in render.get('imported_resources', [])}
for row in mapping['exports']:
    result = imported.get(row['runtime'], {})
    check([result.get('width'), result.get('height')] == row['size'],
          'Imported dimensions missing/wrong: ' + row['runtime'], 'imports')
for role, weight in [('display/title', 700), ('ui/labels', 600), ('ui/location', 500)]:
    font = next((f for f in render['fonts'] if f['path'].endswith(role + '.tres')), {})
    check(font.get('axes') == {'weight': weight, 'width': 100}, 'Actual font RID axes wrong: ' + role, 'fonts')
check(len(current_sheets) >= 33, 'Screen/state coverage incomplete', 'renders')
last_hand = next((s for s in render['sheets'] if s['file'] == 'cards-native-hand-end.png'), {})
check(last_hand.get('hand_scroll', 0) > 0, 'Eight-card hand end inaccessible', 'layout')
text_count = 0
preview_evidence = []
dimensions = set()
modes = set()
for sheet, art_directory in current_sheets:
    path = art_directory / sheet['file']
    check(path.is_file(), 'Missing actual render: ' + sheet['file'], 'renders')
    if path.is_file():
        with Image.open(path) as img:
            check(img.size == (sheet['width'], sheet['height']), 'Wrong render resolution: ' + sheet['file'], 'renders')
        preview_evidence.append({'path': str(path.relative_to(ROOT)).replace('\\', '/'), 'sha256': sha(path)})
    check(not sheet['issues'], 'Sheet layout failed: ' + sheet['file'], 'layout')
    for record in sheet['text_checks']:
        text_count += 1
        check(not record['overflow'], 'Label overflow: ' + record['text'], 'live_text')
    dimensions.add((sheet['width'], sheet['height']))
    modes.add(sheet['mode'])
for expected in [(720, 1600), (450, 1000), (360, 640)]:
    check(expected in dimensions, 'Missing responsive viewport ' + str(expected), 'renders')
for expected in ['components','states','cards','home-save','home-empty','home-invalid','menu-open','menu-locked','options','map','replace','dialog','wordmark']:
    check(expected in modes, 'Missing state specimen ' + expected, 'renders')
for key in ['pointed_edge_click','keyboard_callback','unavailable_suppressed','modal_close_visible']:
    check(render['interaction'].get(key) is True, 'Interaction check failed: ' + key, 'interaction')

# Logs are authoritative too: a script can fail without making Godot's exit code nonzero.
allowed = ["Failed to read the root certificate store", "Can't create shader cache folder", "Could not open 'user://' directory"]
host_warnings = []
logs = [QA / name for name in ['godot-import.log','godot-render.log','interactive-gallery.log']]
logs += [MENU_QA / name for name in ['godot-import.log','godot-render.log']]
for log in logs:
    for line in log.read_text(encoding='utf-8-sig').splitlines():
        if line.startswith(('ERROR:', 'SCRIPT ERROR:')):
            if any(item in line for item in allowed):
                host_warnings.append(line)
            else:
                check(False, str(log.relative_to(ROOT)) + ': ' + line, 'engine_errors')
check(True, 'Engine logs audited', 'engine_errors')

check((ROOT / 'source-assets/.gdignore').is_file(), 'Source exclusion lost', 'packaging')
presets = read('export_presets.cfg')
for exclude in re.findall(r'exclude_filter="([^"]+)"', presets):
    check(all(x in exclude.split(',') for x in ['source-assets/*','output/*','tools/*']), 'Export exclusion lost', 'packaging')
for required in ['source-assets/ui/theme-notes.json','source-assets/ui/ui_dialog_scrim.json','source-assets/ui/delivery.md','docs/ui-theme.md']:
    check((ROOT / required).is_file(), 'Missing handoff ' + required, 'docs')

report = {
    'task':'RC-013', 'result':'PASS' if not errors else 'FAIL', 'counts':counts,
    'checks':sum(counts.values()), 'live_text_measurements':text_count, 'errors':errors,
    'preview_hashes':preview_evidence, 'host_warnings':sorted(set(host_warnings)),
    'retained_render_reports':['output/qa/rc-013/godot-render-results.json','output/qa/rc-013/menu-button-revert/godot-render-results.json'],
    'staged_resource_directory':str(staged.relative_to(ROOT)).replace('\\', '/'),
    'measurement_status':'Layout, font RID and interaction measurements are reused from retained Godot reports; this audit does not execute Godot or claim new rendering.',
    'scope':'Current production sources/import recipes and retained isolated desktop evidence. Not gameplay integration, owner approval, rights clearance or physical-device validation.'
}
report_path = ROOT / args.report
report_path.parent.mkdir(parents=True, exist_ok=True)
report_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: report[k] for k in ['result','checks','counts','errors']}, indent=2))
raise SystemExit(0 if not errors else 1)
