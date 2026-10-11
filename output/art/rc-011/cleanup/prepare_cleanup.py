"""Prepare a bounded art cleanup manifest; this script never deletes files."""
from pathlib import Path
import hashlib
import json
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
SOURCE = ROOT / 'source-assets/pilot'
OUT = ROOT / 'output/art/rc-011'
CURRENT = SOURCE / 'revisions/r006'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def relative(path):
    return path.relative_to(ROOT).as_posix()

# Capture the actual current SVG dependency graph before selecting candidates.
linked = set()
def dependencies(path):
    path = path.resolve()
    if path in linked:
        return
    assert path.is_relative_to(ROOT) and path.is_file(), path
    linked.add(path)
    if path.suffix == '.svg':
        for node in ET.parse(path).getroot().iter():
            href = node.get('{http://www.w3.org/1999/xlink}href') or node.get('href')
            if href and not href.startswith(('data:', '#')):
                dependencies(path.parent / href)
for path in CURRENT.glob('pilot_*.svg'):
    dependencies(path)

r2_files = {
    'assemble_shadeling.py', 'build_shadeling.py', 'delivery.md',
    'shadeling.ora', 'separation-masks.svg', 'metadata.json', 'neutral-reference.png',
    'exports/shadeling.png', 'type-geometry/font-provenance.json',
    'type-geometry/font-measurements.json', 'type-geometry/spark.svg',
}
r4_files = {'build_crypt.py', 'build_review.py', 'delivery.md', 'cross-screen-review.md', 'raw/generation-record.json'}
selected_paints = {'crypt-background', 'empty-tile', 'navy-panel', 'cast-button'}
dead_current = {
    'frame-gold-159x168-12.png', 'frame-green-159x168-12.png',
    'navy-panel-342x337-6.png', 'navy-panel-793x683-10.png',
    'navy-panel-82x78-4.png', 'navy-panel-84x50-3.png',
    'navy-panel-85x85-5.png', 'navy-panel-94x58-4.png',
}

def source_reason(path):
    rel = path.relative_to(SOURCE).as_posix()
    if path.resolve() in linked:
        return None
    if '__pycache__' in path.parts:
        return 'Regenerable Python cache from art tooling'
    if rel in ('delivery.md', 'button/build_materials.py', 'shadeling/assemble_shadeling.py'):
        return None
    if rel.startswith('revisions/r006/'):
        sub = rel.removeprefix('revisions/r006/')
        if sub.startswith('ui/') and (path.name in dead_current or re.fullmatch(r'frame-\d+x\d+-\d+\.png', path.name)):
            return 'Unused size-specific texture cache; absent from current SVG dependency graph'
        return None
    if rel.startswith('revisions/r002/'):
        sub = rel.removeprefix('revisions/r002/')
        if sub in r2_files or sub.startswith(('raw/', 'layers/', 'exports/shadeling_parts/', 'type-geometry/fonts/')):
            return None
        return 'Superseded r002 UI/composition experiment; selected actor/font/motion retained'
    if rel.startswith('revisions/r004/'):
        sub = rel.removeprefix('revisions/r004/')
        if sub in r4_files or sub.startswith('crypt/'):
            return None
        if sub.startswith('raw/') and path.name.removesuffix('.prompt.txt').removesuffix('.png') in selected_paints:
            return None
        if sub.startswith('ui/') and (path.name.endswith('-metadata.json') or path.name.endswith('-mask.svg')):
            return None
        return 'Unused alternative, superseded composition or duplicate r004 material; selected source and canonical r006 copy retained'
    if rel in ('revisions/r003/delivery.md', 'revisions/r005/delivery.md'):
        return None
    return 'Rejected r001 art or superseded reference-adoption/review tool; current dependencies retained separately'

def output_reason(path):
    rel = path.relative_to(OUT).as_posix()
    if rel.startswith('cleanup/'):
        return None
    if path.suffix == '.json':
        return None  # Small historical audit/approval evidence; not alternative artwork.
    if rel.startswith('r006/'):
        if rel.startswith('r006/history/') or path.name == 'reference-label-inspection.png':
            return 'Superseded before-fix archive or temporary reference-inspection image'
        return None
    if rel.startswith('r002/') and (path.name.startswith('pilot-motion') or rel.startswith('r002/pilot-motion-frames/') or path.name.startswith('pilot-shadeling-')):
        return None
    if rel == 'r004/crypt-layers.png':
        return None
    return 'Rejected/superseded preview; corrected r006 preview and selected r002 motion retained'

removed = []
kept = []
for folder, classify in ((SOURCE, source_reason), (OUT, output_reason)):
    for path in sorted(folder.rglob('*')):
        if not path.is_file():
            continue
        reason = classify(path)
        if reason:
            removed.append({'path': relative(path), 'sha256': digest(path), 'bytes': path.stat().st_size, 'reason': reason})
        elif not relative(path).startswith('output/art/rc-011/cleanup/'):
            kept.append(relative(path))
for path in sorted((ROOT / 'output/imagegen').iterdir()):
    if path.is_file():
        assert path.suffix in ('.png', '.txt'), path
        removed.append({'path': relative(path), 'sha256': digest(path), 'bytes': path.stat().st_size, 'reason': 'Unselected/superseded generated reference study; all six exact approved reference images retained'})

removed_paths = {row['path'] for row in removed}
assert not ({relative(p) for p in linked} & removed_paths)
assert not any('/approved/' in p or p.startswith(('assets/', 'scripts/', 'scenes/', 'tests/', 'data/', 'output/qa/')) for p in removed_paths)
assert len(removed_paths) == len(removed)
snapshot_path = OUT / 'r006/preservation-snapshot-validation.json'
snapshot = json.loads(snapshot_path.read_text())
updated = []
for row in snapshot['files']:
    path = ROOT / row['path']
    if row['path'] not in removed_paths and path.is_file() and digest(path) != row['sha256']:
        updated.append({'path': row['path'], 'before_sha256': row['sha256'], 'after_sha256': digest(path), 'reason': 'Retained source recipe or documentation reconciled for explicitly authorized art cleanup'})

guard_paths = set((ROOT / 'output/imagegen/approved').glob('*.png'))
guard_paths.update(OUT.glob('r006/pilot-*.png'))
guard_paths.update((CURRENT / 'exports').glob('*.png'))
guard_paths.update((CURRENT / 'ui').glob('*.ora'))
guard_paths.add(SOURCE / 'revisions/r002/shadeling.ora')
guard_paths.add(SOURCE / 'revisions/r004/crypt/crypt.ora')
record = {
    'status': 'planned', 'date': '2026-10-11',
    'authorization': 'Owner requested deletion of unused/unapproved art and explicitly chose: Keep current pilot, approved references and runtime dependencies.',
    'scope': 'Only unused pilot art/review files and non-approved reference studies. Runtime code/assets/tests/QA and approved reference images excluded.',
    'removed': removed, 'updated': updated,
    'retained_current_integrity': [{'path': relative(p), 'sha256': digest(p)} for p in sorted(guard_paths)],
    'kept_files': kept,
    'planned_file_count': len(removed), 'planned_bytes': sum(row['bytes'] for row in removed),
}
target = HERE / 'deletion-manifest.json'
if target.exists() and json.loads(target.read_text()).get('status') == 'completed':
    raise SystemExit('Completed ledger is immutable; refusing to replace it.')
target.write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'planned_file_count': len(removed), 'planned_MiB': record['planned_bytes'] / 1048576, 'current_SVG_dependency_files_preserved': len(linked), 'selected_visual_files_guarded': len(guard_paths), 'updated_snapshot_files': len(updated)}, indent=2))
