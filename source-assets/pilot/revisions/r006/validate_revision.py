"""Audit r006 review files without changing runtime or historical QA evidence.

Run with --snapshot once before r006 production to record prior review bytes.
Run with --asset-plan for the final audit, restoring RC-010's raw report exactly.
Checks establish file/source integrity, not visual or owner acceptance.
"""
from pathlib import Path
from urllib.parse import unquote
import argparse
import hashlib
import io
import json
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image, ImageChops

P = Path(__file__).resolve().parent
ROOT = P.parents[3]
OLD = P.parent / 'r002'
PAINT = P.parent / 'r004'
OUT = ROOT / 'output/art/rc-011/r006'
OUT.mkdir(parents=True, exist_ok=True)
SVG = '{http://www.w3.org/2000/svg}'
XLINK = '{http://www.w3.org/1999/xlink}'
SNAPSHOT = OUT / 'preservation-snapshot-validation.json'
checks = []
resources = set()
memory = []


def relative(path):
    try:
        return Path(path).resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check(ok, name, evidence=''):
    checks.append({'check': name, 'result': 'pass' if ok else 'FAIL', 'evidence': evidence})
    return bool(ok)


def load_json(path):
    if not check(path.is_file(), 'JSON exists: ' + relative(path), relative(path)):
        return {}
    try:
        return json.loads(path.read_text(encoding='utf-8-sig'))
    except (ValueError, OSError) as exc:
        check(False, 'Valid JSON: ' + relative(path), str(exc))
        return {}


def rgba_same(a, b):
    return a.size == b.size and ImageChops.difference(a.convert('RGBA'), b.convert('RGBA')).getbbox(alpha_only=False) is None


def font_codepoints(path):
    """Read actual Unicode cmap coverage; no system-font fallback is assumed."""
    raw = path.read_bytes()
    tables = {}
    count = struct.unpack_from('>H', raw, 4)[0]
    for index in range(count):
        tag, _, offset, length = struct.unpack_from('>4sIII', raw, 12 + index * 16)
        tables[tag] = (offset, length)
    offset, length = tables[b'cmap']
    cmap = raw[offset:offset + length]
    covered = set()
    for index in range(struct.unpack_from('>H', cmap, 2)[0]):
        platform, encoding, start = struct.unpack_from('>HHI', cmap, 4 + index * 8)
        if not (platform == 0 or (platform == 3 and encoding in (1, 10))):
            continue
        fmt = struct.unpack_from('>H', cmap, start)[0]
        if fmt == 12:
            groups = struct.unpack_from('>I', cmap, start + 12)[0]
            for group in range(groups):
                first, last, glyph = struct.unpack_from('>III', cmap, start + 16 + group * 12)
                covered.update(range(first + (glyph == 0), last + 1))
        elif fmt == 4:
            n = struct.unpack_from('>H', cmap, start + 6)[0] // 2
            end_pos = start + 14
            begin_pos = end_pos + n * 2 + 2
            delta_pos = begin_pos + n * 2
            range_pos = delta_pos + n * 2
            for segment in range(n):
                first = struct.unpack_from('>H', cmap, begin_pos + segment * 2)[0]
                last = struct.unpack_from('>H', cmap, end_pos + segment * 2)[0]
                delta = struct.unpack_from('>h', cmap, delta_pos + segment * 2)[0]
                extra = struct.unpack_from('>H', cmap, range_pos + segment * 2)[0]
                for cp in range(first, min(last, 65534) + 1):
                    if extra:
                        glyph_pos = range_pos + segment * 2 + extra + 2 * (cp - first)
                        glyph = struct.unpack_from('>H', cmap, glyph_pos)[0]
                        glyph = (glyph + delta) & 0xffff if glyph else 0
                    else:
                        glyph = (cp + delta) & 0xffff
                    if glyph:
                        covered.add(cp)
    return covered


def image_check(path, size=None, rgba=False, icc=False):
    if not check(path.is_file(), 'Image exists: ' + relative(path), relative(path)):
        return None
    try:
        with Image.open(path) as original:
            original.load()
            im = original.copy()
            check(size is None or im.size == size, 'Image dimensions: ' + relative(path), list(im.size))
            if rgba:
                check(im.mode == 'RGBA', 'Straight-alpha RGBA container: ' + relative(path), im.mode)
            if icc:
                check(bool(original.info.get('icc_profile')), 'Embedded colour profile: ' + relative(path), 'ICC profile present' if original.info.get('icc_profile') else 'missing')
            return im
    except (OSError, ValueError) as exc:
        check(False, 'Image decodes: ' + relative(path), str(exc))
        return None


def audit_ora(path, expected_size=None, min_layers=2):
    if not check(path.is_file(), 'ORA source exists: ' + relative(path), relative(path)):
        return
    try:
        with zipfile.ZipFile(path) as archive:
            check(archive.read('mimetype') == b'image/openraster', 'ORA mimetype: ' + relative(path))
            tree = ET.fromstring(archive.read('stack.xml'))
            size = (int(tree.get('w')), int(tree.get('h')))
            check(expected_size is None or size == expected_size, 'ORA source canvas: ' + relative(path), list(size))
            layers = tree.findall('.//layer')
            check(len(layers) >= min_layers, 'Layer count: ' + relative(path), len(layers))
            composed = Image.new('RGBA', size)
            layer_hashes = []
            supported = True
            for layer in reversed(layers):
                im = Image.open(io.BytesIO(archive.read(layer.get('src')))).convert('RGBA')
                layer_hashes.append(hashlib.sha256(im.tobytes()).hexdigest())
                check(im.getchannel('A').getbbox() is not None, 'Nonempty layer: ' + relative(path) + '/' + layer.get('name', ''), list(im.size))
                supported &= layer.get('composite-op', 'svg:src-over') == 'svg:src-over'
                supported &= float(layer.get('opacity', '1')) == 1
                if layer.get('visibility', 'visible') != 'hidden':
                    composed.alpha_composite(im, (int(layer.get('x', 0)), int(layer.get('y', 0))))
            check(len(set(layer_hashes)) == len(layers), 'Distinct layer pixels: ' + relative(path), 'No duplicated flattened layers')
            merged = Image.open(io.BytesIO(archive.read('mergedimage.png'))).convert('RGBA')
            check(merged.size == size, 'ORA merged canvas: ' + relative(path), list(merged.size))
            if supported:
                check(rgba_same(composed, merged), 'ORA exact source recomposition: ' + relative(path))
            else:
                check(False, 'ORA recomposition supported by auditor: ' + relative(path), 'Non-default opacity/blend mode requires an independent renderer comparison')
    except (OSError, ValueError, KeyError, zipfile.BadZipFile, ET.ParseError) as exc:
        check(False, 'ORA decodes: ' + relative(path), str(exc))


def audit_svg(path, editable=False, seen=None):
    seen = set() if seen is None else seen
    path = path.resolve()
    if path in seen:
        return None
    seen.add(path)
    if not check(path.is_file(), 'SVG source exists: ' + relative(path), relative(path)):
        return None
    try:
        tree = ET.parse(path).getroot()
    except (OSError, ET.ParseError) as exc:
        check(False, 'SVG parses: ' + relative(path), str(exc))
        return None
    check(tree.tag == SVG + 'svg', 'SVG namespace: ' + relative(path))
    if editable:
        check(bool(tree.findall('.//' + SVG + 'text')), 'Editable live text: ' + relative(path))
        check(any(tree.findall('.//' + SVG + tag) for tag in ('path', 'rect', 'line', 'polyline', 'polygon')), 'Editable geometry: ' + relative(path))
    for element in tree.iter():
        href = element.get(XLINK + 'href') or element.get('href')
        if not href or href.startswith('#'):
            continue
        if href.startswith('data:'):
            check(False, 'Linked editable resource: ' + relative(path), 'Embedded data resource; canonical source must link the editable file')
            continue
        if re.match(r'^[A-Za-z][A-Za-z0-9+.-]*:', href):
            check(False, 'Local linked resource: ' + relative(path), href)
            continue
        target = (path.parent / unquote(href.split('#')[0])).resolve()
        if not check(target.is_file(), 'Resolved linked resource: ' + relative(path), relative(target)):
            continue
        resources.add(target)
        # Canonical production previews may not use a complete approved/reference screenshot as art.
        forbidden = ROOT / 'output/imagegen'
        check(not target.is_relative_to(forbidden), 'No generation-history/reference underlay: ' + relative(path), relative(target))
        if target.suffix.lower() == '.svg':
            audit_svg(target, seen=seen)
        elif target.suffix.lower() in ('.png', '.jpg', '.jpeg', '.webp'):
            check(digest(target) not in approved_hashes, 'No renamed approved screenshot as linked art: ' + relative(path), relative(target))
    return tree


def check_links(doc):
    if not check(doc.is_file(), 'Delivery document exists: ' + relative(doc), relative(doc)):
        return
    for link in re.findall(r'\]\(([^)]+)\)', doc.read_text(encoding='utf-8-sig')):
        link = link.strip('<>').split(' "')[0]
        if re.match(r'[a-z][a-z0-9+.-]*:', link, re.I):
            continue
        filepart = unquote(link.partition('#')[0])
        target = (doc.parent / filepart).resolve() if filepart else doc
        check(target.exists(), 'Delivery link: ' + relative(doc), link)


def audit_clean_board(tree, source_name, group_id, endpoints_required=False):
    """Inspect actual SVG descendants, keeping captions outside the board legal."""
    if tree is None:
        return
    groups = [el for el in tree.iter() if el.get('id') == group_id]
    if not check(bool(groups), 'Explicit editable board group: ' + source_name, group_id):
        return
    labels = []
    for group in groups:
        for node in group.iter():
            if node.tag == SVG + 'text':
                labels.append(' '.join(''.join(node.itertext()).split()))
            if any(node.get(attr) not in (None, 'none') for attr in ('marker-start', 'marker-mid', 'marker-end')):
                check(False, 'No circuit flow marker inside board: ' + source_name, node.attrib)
    check(all(label.upper() in ('BEGIN', 'END') for label in labels), 'Clean board contains only BEGIN/END text: ' + source_name, labels)
    if endpoints_required:
        check({label.upper() for label in labels} == {'BEGIN', 'END'}, 'Begin and End remain labelled: ' + source_name, labels)


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--snapshot', action='store_true')
parser.add_argument('--asset-plan', action='store_true')
args = parser.parse_args()
if args.snapshot:
    if SNAPSHOT.exists():
        raise SystemExit('Snapshot already exists; refusing to replace preservation evidence.')
    paths = set((ROOT / 'output/imagegen/approved').glob('*.png'))
    for revision in ('r002', 'r003', 'r004', 'r005'):
      for folder in (P.parent / revision, ROOT / 'output/art/rc-011' / revision):
        paths.update(p for p in folder.rglob('*') if p.is_file() and '__pycache__' not in p.parts)
    record = {'purpose': 'Exact previous revision/reference preservation before r006 work; not updated on audit reruns', 'files': [{'path': relative(p), 'sha256': digest(p)} for p in sorted(paths)]}
    SNAPSHOT.write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'snapshot': relative(SNAPSHOT), 'files': len(paths)}))
    raise SystemExit(0)

approved_hashes = {digest(p) for p in (ROOT / 'output/imagegen/approved').glob('*.png')}
baseline = load_json(ROOT / 'output/qa/rc-010/preservation-baseline.json')
protected_changes = []
for row in baseline if isinstance(baseline, list) else []:
    path = ROOT / row['path']
    if not path.is_file() or digest(path) != row['sha256']:
        protected_changes.append(row['path'])
check(len(baseline) == 974 and not protected_changes, '974 protected runtime/reference/raw-evidence files preserved', protected_changes)
snapshot = load_json(SNAPSHOT)
prior_changes = []
for row in snapshot.get('files', []):
    path = ROOT / row['path']
    if not path.is_file() or digest(path) != row['sha256']:
        prior_changes.append(row['path'])
check(bool(snapshot.get('files')) and not prior_changes, 'Prior r002/r003/r004/r005 sources, previews and approved references preserved', prior_changes)

for name, size in {
    'pilot-841x1870.png': (841, 1870), 'pilot-720x1600.png': (720, 1600),
    'pilot-450x1000.png': (450, 1000), 'pilot-360x640.png': (360, 640),
}.items():
    image_check(OUT / name, size)
for name in ('pilot-states.png', 'pilot-type.png'):
    image_check(OUT / name)

trees = {}
for name in ('pilot_review.svg', 'pilot_narrow.svg', 'pilot_narrow_controls.svg', 'pilot_states.svg', 'pilot_type.svg', 'pilot_tile_states.svg'):
    trees[name] = audit_svg(P / name, editable=True)
for name in ('pilot_review.svg', 'pilot_narrow.svg'):
    audit_clean_board(trees.get(name), name, 'gameplay-board', endpoints_required=True)
for name in ('pilot_states.svg', 'pilot_tile_states.svg'):
    audit_clean_board(trees.get(name), name, 'board-samples')
main = trees.get('pilot_review.svg')
if main is not None:
    labels = [''.join(el.itertext()).strip() for el in main.findall('.//' + SVG + 'text')]
    visible = ' | '.join(labels)
    for word in ('BOSS', 'Remove', 'Rotate', 'Draw', 'Discard', 'Damage', 'Shield', 'Cost', 'Incoming', 'Cast', 'Menu', 'Map', 'Guide', 'Sound'):
        check(bool(re.search(r'\b' + re.escape(word) + r'\b', visible, re.I)), 'Required editable UI label: ' + word, word)
    for forbidden in ('Flip', 'Undo', 'Inspect', 'Cancel', 'Pass', 'placeholder', 'blockout'):
        check(not re.search(r'\b' + re.escape(forbidden) + r'\b', visible, re.I), 'No obsolete/placeholder UI label: ' + forbidden)
    check(not any(any(el.get(attr) for attr in ('marker-start', 'marker-mid', 'marker-end')) for el in main.iter()), 'No directional marker arrowheads in main circuit SVG', 'Rotate icon paths are permitted editing-action symbols')
    board_nodes = {id(node) for group in main.iter() if group.get('id') == 'gameplay-board' for node in group.iter()}
    for glyph_name in ('split', 'join'):
        glyph = audit_svg(P / 'ui' / (glyph_name + '.svg'))
        if glyph is not None:
            check(not any(node.tag in (SVG + 'text', SVG + 'image') for node in glyph.iter()), 'Standalone glyph is editable vector geometry: ' + glyph_name)
            for path in glyph.findall('.//' + SVG + 'path'):
                geometry = path.get('d')
                matches = [node for node in main.findall('.//' + SVG + 'path') if node.get('d') == geometry]
                check(any(id(node) in board_nodes for node in matches) and any(id(node) not in board_nodes for node in matches), 'Same glyph geometry on board and toolbar: ' + glyph_name, geometry)

composition = load_json(P / 'ui/composition-metadata.json')
reuse = load_json(P / 'ui/reuse-dependencies.json')
for item in reuse.get('copied_painted_sources', []):
    current = (P / item['current']).resolve()
    origin = (P / item['origin']).resolve()
    check(current.is_file() and origin.is_file() and digest(current) == digest(origin) == item.get('sha256'), 'Actual byte-preserved source copy: ' + item['current'], relative(origin))
for name in reuse.get('retained_source_dependencies', []):
    check((P / name).resolve().is_file(), 'Retained editable dependency exists', name)
current_reference = ROOT / 'output/imagegen/approved/combat-final-v2-clean-board.png'
check(current_reference.is_file() and digest(current_reference) == 'ad5e7429a79c53d65c6ef00e5094b83b58738b10715a2478c64230bdbc6688ac', 'Current owner-approved clean-board reference preserved', relative(current_reference))
check(set(composition.get('editing_actions', [])) == {'Remove', 'Rotate'}, 'Declared editor actions match approved change', composition.get('editing_actions'))
narrow = composition.get('native_narrow', {})
check(narrow.get('cell_size') == 72 and narrow.get('viewport') == [360, 640], 'Native narrow viewport and cell scale', narrow)
check(bool(narrow.get('scroll_boundary')), 'Narrow scrolling boundary documented', narrow.get('scroll_boundary'))
check(composition.get('canonical_ports') == {'N': [64, 0], 'E': [128, 64], 'S': [64, 128], 'W': [0, 64]}, 'Canonical undirected edge ports', composition.get('canonical_ports'))
check(set(composition.get('sample_rotations', [])) == {0, 90, 180, 270}, 'Four rotation specimens documented', composition.get('sample_rotations'))
check({24, 32, 48} <= set(composition.get('glyph_sizes', [])), 'Required actual-size glyph specimens documented', composition.get('glyph_sizes'))
required_states = {'normal', 'pressed', 'focused', 'selected', 'disabled', 'invalid', 'unavailable', 'focused+selected', 'focused+unavailable'}
check(required_states <= set(composition.get('state_tokens', [])), 'Button state coverage documented', composition.get('state_tokens'))
tile_states = {'unpowered', 'powered', 'selected', 'focused', 'invalid', 'unavailable', 'focused+selected'}
check(tile_states <= set(composition.get('tile_state_tokens', [])), 'Spark tile state coverage documented', composition.get('tile_state_tokens'))
tile_states_source = composition.get('tile_states_source')
if check(bool(tile_states_source), 'Spark tile state source identified', tile_states_source):
    audit_svg(P / tile_states_source, editable=True)

# Retained selected layered sources are reused rather than falsely regenerated.
audit_ora(OLD / 'shadeling.ora', (1024, 1024), 7)
for key, size in (('tile', (512, 512)), ('primary', (1024, 256)), ('secondary', (1024, 256))):
    path = P / composition.get('painted_sources', {}).get(key, '__missing_' + key + '_source__')
    audit_ora(path, size)
for key, size in (('tile', (256, 256)), ('primary', (512, 128)), ('secondary', (512, 128))):
    path = P / composition.get('material_exports', {}).get(key, '__missing_' + key + '__')
    image_check(path, size, rgba=True, icc=True)
image_check(OLD / 'exports/shadeling.png', (512, 512), rgba=True, icc=True)
actor = load_json(OLD / 'metadata.json')
check(actor.get('source_foot') == [512, 896] and actor.get('export_foot') == [256, 448], 'Character common foot anchors', actor.get('export_foot'))
combined = Image.new('RGBA', (512, 512))
for name in actor.get('draw_order', []):
    part = image_check(OLD / 'exports/shadeling_parts' / (name + '.png'), (512, 512), rgba=True, icc=True)
    if part is not None:
        combined.alpha_composite(part)
neutral_path = OLD / 'exports/shadeling.png'
if neutral_path.is_file():
    check(rgba_same(combined, Image.open(neutral_path)), 'Actor parts reconstruct neutral export exactly')
generation = actor.get('generation', {})
raw = OLD / generation.get('raw_path', '__missing__')
check(raw.is_file() and digest(raw) == generation.get('raw_sha256'), 'Character raw generation retained', relative(raw))

crypt = image_check(P / composition.get('source_mapping', {}).get('environment', '__missing_environment__'), (841, 1870), rgba=True, icc=True)
crypt_sources = list((PAINT / 'crypt').glob('*.ora'))
check(bool(crypt_sources), 'Editable crypt ORA master present', [relative(p) for p in crypt_sources])
for path in crypt_sources:
    audit_ora(path)
crypt_meta = load_json(PAINT / 'crypt/metadata.json')
generation_record = load_json(PAINT / 'raw/generation-record.json')
for record in generation_record.get('records', []):
    for item, expected in (('asset', 'asset_sha256'), ('prompt', 'prompt_sha256')):
        path = PAINT / 'raw' / record[item]
        check(path.is_file() and digest(path) == record.get(expected), 'Retained generation record: ' + record[item], {'selected': record.get('selected'), 'sha256': record.get(expected)})
crypt_generation = crypt_meta.get('generation', {})
crypt_raw = (PAINT / 'crypt' / crypt_generation.get('raw', '__missing__')).resolve()
crypt_prompt = (PAINT / 'crypt' / crypt_generation.get('prompt', '__missing__')).resolve()
check(crypt_raw.is_file() and digest(crypt_raw) == crypt_generation.get('raw_sha256'), 'Retained raw crypt generation hash', relative(crypt_raw))
check(crypt_prompt.is_file() and bool(crypt_prompt.read_text(encoding='utf-8-sig').strip()), 'Exact crypt generation prompt retained', relative(crypt_prompt))
ref_path = ROOT / crypt_generation.get('reference', '__missing__')
check(ref_path.is_file() and digest(ref_path) == crypt_generation.get('reference_sha256'), 'Crypt reference preserved and identified by hash', relative(ref_path))
check(crypt_meta.get('production_reference_crop') is False, 'Crypt provenance explicitly excludes reference-pixel crop', crypt_meta.get('production_reference_crop'))
check(bool(crypt_meta.get('editability')) and 'Hidden' in crypt_meta.get('editability', ''), 'Crypt source separation limitation disclosed', crypt_meta.get('editability'))
crypt_layers = crypt_meta.get('layers', [])
check(len(crypt_layers) >= 2, 'Crypt semantic layer mapping present', len(crypt_layers))
if crypt is not None:
    restored = Image.new('RGBA', crypt.size)
    for layer in crypt_layers:
        path = PAINT / 'crypt' / layer['path']
        part = image_check(path, crypt.size, rgba=True, icc=True)
        if part is not None:
            restored.alpha_composite(part)
    check(rgba_same(crypt, restored), 'Crypt named semantic layer exports reconstruct review background exactly')

font = load_json(OLD / 'type-geometry/font-provenance.json')
font_path = OLD / 'type-geometry/fonts/NotoSerif-Variable.ttf'
licence_path = OLD / 'type-geometry/fonts/OFL.NotoSerif.txt'
check(font_path.is_file() and digest(font_path) == font.get('font_sha256'), 'Actual Noto Serif font matches acquired provenance', relative(font_path))
check(licence_path.is_file() and digest(licence_path) == font.get('licence_sha256'), 'Actual font licence matches acquired provenance', relative(licence_path))
if licence_path.is_file():
    check('SIL OPEN FONT LICENSE' in licence_path.read_text(encoding='utf-8-sig'), 'Actual OFL licence text retained')
if font_path.is_file():
    coverage = font_codepoints(font_path)
    for name, tree in trees.items():
        if tree is not None:
            rendered_text = ''.join(''.join(el.itertext()) for el in tree.findall('.//' + SVG + 'text'))
            missing = sorted({char for char in rendered_text if not char.isspace() and ord(char) not in coverage})
            check(not missing, 'Actual font covers visible SVG characters: ' + name, [f'{char} U+{ord(char):04X}' for char in missing])

motion_dir = ROOT / 'output/art/rc-011/r002'
timing = load_json(motion_dir / 'pilot-motion-timing.json')
records = timing.get('frames', [])
check(timing.get('fps') == 8 and len(records) == 96 and len({r['frame'] for r in records}) == 48, 'Retained authoritative 48-frame motion sequence and paired reduced records', {'records': len(records), 'fps': timing.get('fps')})
check({'IDLE', 'ATTACK', 'HIT', 'DEFEAT'} <= {r['state'].split()[0] for r in records}, 'Motion covers four required states', sorted({r['state'] for r in records}))
check({False, True} == {r.get('reduced') for r in records}, 'Reduced-motion counterpart retained')
for record in records:
    b = record.get('alpha_bounds_all')
    check(b is None or (b[0] >= 32 and b[1] >= 32 and b[2] <= 480 and b[3] <= 480), 'Motion envelope: frame ' + str(record['frame']) + ', reduced=' + str(record.get('reduced')), b)
sequence = list((motion_dir / 'pilot-motion-frames').glob('frame_*.png'))
check(len(sequence) == 48, 'Actual PNG sequence exists', len(sequence))
for path in sequence:
    image_check(path)

check((ROOT / 'source-assets/.gdignore').is_file() and (ROOT / 'output/.gdignore').is_file(), 'Source and review import exclusions remain present')

# Physical dimensions, not compressed PNG sizes; list precisely what is counted.
candidate_pngs = {OLD / 'exports/shadeling.png'} | set((OLD / 'exports/shadeling_parts').glob('*.png'))
candidate_pngs.update((P / value).resolve() for value in composition.get('material_exports', {}).values())
environment_path = (P / composition.get('source_mapping', {}).get('environment', '__missing_environment__')).resolve()
if environment_path.is_file():
    candidate_pngs.add(environment_path)
for path in sorted(candidate_pngs):
    if path.is_file():
        with Image.open(path) as im:
            memory.append({'path': relative(path), 'size': list(im.size), 'assumed_format': 'RGBA8', 'decoded_bytes': im.width * im.height * 4})

asset_plan = None
if args.asset_plan:
    historical = ROOT / 'output/qa/rc-010/validation-report.json'
    original = historical.read_bytes()
    try:
        result = subprocess.run([sys.executable, str(ROOT / 'tools/validate_asset_plan.py')], cwd=ROOT, capture_output=True, text=True, encoding='utf-8')
        asset_plan = json.loads(result.stdout)
        (OUT / 'asset-plan-validation.json').write_text(json.dumps(asset_plan, indent=2) + '\n', encoding='utf-8')
        check(result.returncode == 0 and asset_plan.get('result') == 'PASS', 'Existing asset-plan validator', asset_plan.get('errors', []))
    finally:
        historical.write_bytes(original)
    check(historical.read_bytes() == original, 'Historical raw RC-010 validation report restored byte-for-byte')

check_links(P / 'delivery.md')

failed = [row for row in checks if row['result'] == 'FAIL']
report = {
    'task': 'RC-011', 'revision': 'r006', 'date': '2026-10-11',
    'structural_result': 'PASS' if not failed else 'FAIL', 'check_count': len(checks),
    'failures': failed, 'checks': checks,
    'linked_resources': [relative(path) for path in sorted(resources)],
    'review_file_sha256': {relative(path): digest(path) for path in sorted(OUT.glob('pilot-*.png'))},
    'decoded_candidate_pngs': {'bytes': sum(row['decoded_bytes'] for row in memory), 'MiB': sum(row['decoded_bytes'] for row in memory) / 1048576, 'items': memory, 'scope': 'Selected material/background paths declared by r006, plus retained r002 neutral and seven actor parts concurrently. Excludes superseded UI exports, source ORAs/raws/review PNGs, fonts, transient preview surfaces, SVG rasterizations, engine buffers. Not a runtime loading or device measurement.'},
    'asset_plan_run': args.asset_plan,
    'visual_acceptance': 'Not established by file checks. Actual exported visual comparison and review are required; no owner approval inferred.',
    'limits': 'Reference-link/hash checks rule out a direct approved screenshot underlay, not all possible copied crops. Raw provenance and actual visual inspection remain necessary. Undirected gameplay is a design target only; runtime, Godot imports, touch behavior and devices are untested.'
}
(OUT / 'revision-validation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({key: report[key] for key in ('structural_result', 'check_count', 'failures', 'asset_plan_run')}, indent=2))
raise SystemExit(bool(failed))
