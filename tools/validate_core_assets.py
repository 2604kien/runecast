"""RC-012 delivery audit. No gameplay execution or source mutation."""
from pathlib import Path
import csv
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
QA = ROOT / 'output/qa/rc-012'
errors, checks = [], []
def check(ok, label):
    checks.append(label)
    if not ok:
        errors.append(label)
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def read_json(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))

snapshot = read_json('output/qa/rc-012/preservation-before.json')
for row in snapshot:
    p = ROOT / row['path']
    check(p.is_file() and sha(p) == row['sha256'], 'Preserve: '+row['path'])
metadata = read_json('source-assets/icons/core_symbols.json')
check(len(metadata['symbols']) == 24, 'Exactly 24 scoped SVGs')
check(len({r['id'] for r in metadata['symbols']}) == 24, 'Unique stable symbol IDs')
exports = set()
for row in metadata['symbols']:
    src, dst = ROOT / row['source'], ROOT / row['runtime']
    exports.add(dst)
    check(sha(src) == sha(dst) == row['sha256'], 'Source/export/hash: '+row['id'])
    staged = QA / 'preview-project' / row['runtime']
    check(staged.is_file() and sha(dst) == sha(staged), 'Actually imported identical export: '+row['id'])
    tree = ET.parse(src).getroot()
    check(tree.get('viewBox') == '0 0 128 128', 'SVG128: '+row['id'])
    check(not any(e.tag.rsplit('}',1)[-1] in ['image','text','foreignObject','script'] for e in tree.iter()), 'Path-only glyph: '+row['id'])
    content = src.read_text(encoding='utf-8')
    check(not re.search(r'(?:href\s*=|marker-end|marker-start|<filter)',content), 'No dependencies/flow markers: '+row['id'])
    settings = Path(str(dst)+'.import').read_text(encoding='utf-8-sig')
    check('svg/scale=2.0' in settings and 'mipmaps/generate=false' in settings and 'compress/mode=0' in settings, 'Actual SVG import profile: '+row['id'])
check(set((ROOT/'assets/icons').rglob('*.svg')) == exports, 'No unassigned/retired icon exports')
check({p.name for p in (ROOT/'assets/icons/editing').glob('*.svg')} == {'remove.svg','rotate.svg'}, 'Only Remove/Rotate editing exports')
check(sha(ROOT/'assets/icons/symbol_tint.gdshader') == sha(ROOT/'source-assets/icons/symbol_tint.gdshader'), 'Source/runtime tint shader match')
check(sha(ROOT/'assets/icons/symbol_tint.gdshader') == sha(QA/'preview-project/assets/icons/symbol_tint.gdshader'), 'Actually rendered final shader')

font = ROOT/'assets/fonts/ui/NotoSerif-Variable.ttf'
check(sha(font) == sha(ROOT/'source-assets/pilot/revisions/r002/type-geometry/fonts/NotoSerif-Variable.ttf'), 'Unmodified retained font binary')
check(len(list((ROOT/'assets/fonts').rglob('*.ttf'))) == 1, 'One shared runtime binary')
check(sha(font) == sha(QA/'preview-project/assets/fonts/ui/NotoSerif-Variable.ttf'), 'Actually imported identical font')
check(sha(ROOT/'assets/fonts/ui/OFL.NotoSerif.txt') == sha(ROOT/'source-assets/pilot/revisions/r002/type-geometry/fonts/OFL.NotoSerif.txt'), 'Exact retained OFL licence')
probe = read_json('output/qa/rc-012/font-godot-probe.json')
check(probe['pass'] and not probe['base_font']['allow_system_fallback'], 'Godot actual font/axes/coverage/fallback probe')
for role,weight in [('ui/labels',600),('ui/location',500),('display/title',700)]:
    data = probe['roles'][role]
    check(all(r['weight']==weight and r['width']==100 for r in data['render_rid_variations']), 'Instantiated variation: '+role)
    check(not data['missing_characters'], 'Covered font characters: '+role)

render = read_json('output/qa/rc-012/godot-render-results.json')
check(render['result']=='PASS' and not render['errors'], 'Godot rendered test result')
check(len(render['sheets']) == 9, 'Nine actual Godot sheets')
for sheet in render['sheets']:
    check((ROOT/'output/art/rc-012'/sheet['file']).is_file(), 'Rendered PNG: '+sheet['file'])
    check(not sheet['issues'] and sheet['live_text_checks']>0, 'Live glyph coverage/width/height: '+sheet['file'])
    for name,t in sheet['textures'].items():
        check(t['width']==256 and t['height']==256 and not t['mipmaps'], 'Imported size/filter budget: '+name+'/'+sheet['file'])
        check(all(r['edge_indices']==r['expected'] for r in t['quarter_turn_edges']), 'Actual imported alpha edges rotate: '+name+'/'+sheet['file'])
# This restricted Windows session has no usable Godot user-data/OS certificate access.
# These exact host diagnostics are retained in the report, not treated as resource failures.
# Any other error (including a different path failure) fails the audit.
known_warnings = ["Can't create shader cache folder, no shader caching will happen: user://",'Failed to read the root certificate store.',"Could not open 'user://' directory: 'user://'."]
host_warnings = []
for file in ['godot-import.log','godot-render.log']:
    log = (QA/file).read_text(encoding='utf-8-sig')
    for line in log.splitlines():
        if 'ERROR:' in line:
            if line.startswith('ERROR: ') and line[7:] in known_warnings:
                host_warnings.append({'log':file,'message':line[7:]})
            else:
                check(False,'Unexpected Godot error: '+line)

check((ROOT/'source-assets/.gdignore').exists() and (ROOT/'output/.gdignore').exists(), 'Masters/previews import exclusions')
config = (ROOT/'export_presets.cfg').read_text(encoding='utf-8-sig')
check(config.count('source-assets/*')==2, 'Both platform presets exclude masters')
check(config.count('assets/fonts/ATTRIBUTION.txt,assets/fonts/ui/OFL.NotoSerif.txt')==2, 'Both platform presets include font rights')

visual = read_json('output/qa/rc-012/visual-review.json')
check(visual['status']=='pass' and not visual['failures'] and len(visual['files'])==9, 'Independent visual review of nine final sheets')
for row in visual['files']:
    check(sha(ROOT/row['path']) == row['sha256'], 'Reviewed PNG remains current: '+row['path'])

docs = list((ROOT/'source-assets/icons').rglob('*.md')) + list((ROOT/'source-assets/fonts').rglob('*.md'))
for doc in docs:
    for ref in re.findall(r'\]\(([^)]+)\)', doc.read_text(encoding='utf-8-sig')):
        if re.match(r'[a-zA-Z]+:',ref): continue
        filename = unquote(ref).split('#')[0]
        check((doc.parent/filename).exists(), 'Source document link: '+str(doc.relative_to(ROOT))+' -> '+ref)

report = {'task':'RC-012','result':'PASS' if not errors else 'FAIL','checks':len(checks),'errors':errors,
          'protected_files':len(snapshot),'source_runtime_svg_pairs':24,'actual_godot_sheets':len(render['sheets']),
          'live_text_measurements':sum(s['live_text_checks'] for s in render['sheets']),
          'unique_imported_rotation_cases':24*4,'decoded_icon_bytes':24*256*256*4,
          'host_environment_warnings':host_warnings,
          'preservation_scope':'Approved references, all retained pilot sources, scripts/core/UI, data, scenes, tests, project.godot and tools/godot.ps1 remain byte-identical.',
          'export_settings_scope':'Only source-assets exclusions and exact font licence/attribution includes; strict original-byte reconstruction in asset-plan validator.',
          'limits':'Desktop GL Compatibility asset specimens; no game integration, gameplay-suite rerun, owner approval of reconstruction, platform export or physical-device acceptance.'}
(QA/'validation-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
raise SystemExit(bool(errors))
