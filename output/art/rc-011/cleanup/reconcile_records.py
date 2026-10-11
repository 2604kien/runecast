"""Reconcile current indexes and links with the prepared art deletion list."""
from pathlib import Path
from urllib.parse import unquote
import csv
import io
import json
import os
import re

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
ledger = json.loads((HERE / 'deletion-manifest.json').read_text())
assert ledger['status'] == 'planned', 'Reconcile before the recorded deletion'
removed = {(ROOT / row['path']).resolve() for row in ledger['removed']}
kept = {(ROOT / path).resolve() for path in ledger['kept_files']}
kept.update(p.resolve() for p in (ROOT / 'output/imagegen/approved').glob('*.png'))
cleanup_doc = ROOT / 'docs/asset-cleanup.md'

def retired(target):
    if target in removed:
        return True
    # Only reason over the finite audited art inventory; never enumerate the
    # project/toolchain or filesystem when a document links a parent directory.
    if any(target.is_relative_to(ROOT / area) for area in ('source-assets/pilot', 'output/art/rc-011', 'output/imagegen')) and target.is_dir():
        children = [p for p in removed | kept if p.is_relative_to(target)]
        return bool(children) and all(p in removed for p in children)
    return False

changed_docs = []
documents = list((ROOT / 'docs').glob('*.md')) + [ROOT / 'README.md']
documents += [p for p in (ROOT / 'source-assets/pilot').rglob('*.md') if p.resolve() not in removed]
for doc in documents:
    before = doc.read_text(encoding='utf-8-sig')
    destination = Path(os.path.relpath(cleanup_doc, doc.parent)).as_posix()
    def replacement(match):
        image, label, ref = match.groups()
        filename = unquote(ref.strip('<>').split(' "')[0].partition('#')[0])
        if not filename or re.match(r'[a-zA-Z][a-zA-Z0-9+.-]*:', filename):
            return match.group(0)
        target = (doc.parent / filename).resolve()
        if retired(target):
            return f'[{label} — retired in authorized cleanup]({destination})'
        return match.group(0)
    after = re.sub(r'(!?)\[([^\]]*)\]\(([^)]+)\)', replacement, before)
    if after != before:
        doc.write_text(after, encoding='utf-8')
        changed_docs.append(doc.relative_to(ROOT).as_posix())

manifest = ROOT / 'docs/asset-inventory.csv'
lines = manifest.read_bytes().decode('utf-8').splitlines(keepends=True)
header = next(csv.reader([lines[0]]))
out = [lines[0]]
changed_ids = []
record_path = 'output/art/rc-011/cleanup/deletion-manifest.json'
for line in lines[1:]:
    if not line.strip():
        out.append(line)
        continue
    row = dict(zip(header, next(csv.reader([line]))))
    old = row.copy()
    for field in ('current_paths', 'evidence_paths', 'source_master_path', 'runtime_destination'):
        values = row[field].split(';')
        filtered = [v for v in values if not retired((ROOT / v).resolve())]
        if filtered != values:
            row[field] = ';'.join(filtered or [record_path])
            if record_path not in row['evidence_paths'].split(';'):
                row['evidence_paths'] += ';' + record_path
    if row['id'] == 'reference_history':
        row.update(source_master_path=record_path, source_path_state='existing', current_paths=record_path,
                   format='JSON retirement ledger with original image/prompt hashes',
                   generation_reference='Original study image/prompt hashes and reasons recorded in ' + record_path,
                   description='Retired visual studies; exact approved references retained separately',
                   notes='Owner-authorized cleanup removed all 15 unselected/superseded generated study pairs; the six approved PNGs and selected production-paint prompts remain. Historical baseline evidence is unchanged.',
                   evidence_paths='docs/asset-cleanup.md;' + record_path)
    if row != old:
        changed_ids.append(row['id'])
        buffer = io.StringIO(newline='')
        csv.writer(buffer, quoting=csv.QUOTE_ALL, lineterminator='\r\n' if line.endswith('\r\n') else '\n').writerow([row[k] for k in header])
        out.append(buffer.getvalue())
    else:
        out.append(line)
manifest.write_bytes(''.join(out).encode('utf-8'))
result = {'documents_reconciled': changed_docs, 'manifest_rows_reconciled': changed_ids,
          'method': 'Removed-file Markdown links now identify retirement and point to the authorized cleanup record; dated historical prose and raw QA reports are retained.'}
(HERE / 'record-reconciliation.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps(result, indent=2))
