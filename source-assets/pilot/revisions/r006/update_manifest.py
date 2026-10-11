"""Reconcile only the four pilot rows with the final-v2 editable review."""
from pathlib import Path
import csv
import io
import json

P = Path(__file__).resolve().parent
ROOT = P.parents[3]
path = ROOT / 'docs/asset-inventory.csv'
lines = path.read_bytes().decode('utf-8').splitlines(keepends=True)
header = next(csv.reader([lines[0]]))
prefix = 'source-assets/pilot/revisions/r006/'
paint = 'source-assets/pilot/revisions/r004/'
actor = 'source-assets/pilot/revisions/r002/'
sources = {
    'pilot_shadeling': actor + 'shadeling.ora',
    'pilot_spark_tile': prefix + 'ui/painted_tile.ora;' + prefix + 'ui/spark.svg',
    'pilot_button': prefix + 'ui/cast-button.ora;' + prefix + 'ui/navy-panel.ora',
    'pilot_review': prefix + 'pilot_review.svg;' + paint + 'crypt/crypt.ora',
}
exports = {
    'pilot_shadeling': actor + 'exports/shadeling.png;' + actor + 'exports/shadeling_parts/',
    'pilot_spark_tile': prefix + 'exports/spark_tile.png;' + prefix + 'ui/spark.svg',
    'pilot_button': prefix + 'exports/button_primary.png;' + prefix + 'exports/button_secondary.png',
    'pilot_review': 'output/art/rc-011/r006/',
}
generation = {
    'pilot_shadeling': actor + 'raw/shadeling.prompt.txt;' + actor + 'metadata.json',
    'pilot_spark_tile': paint + 'raw/empty-tile.prompt.txt;' + prefix + 'ui/painted-frame-metadata.json',
    'pilot_button': paint + 'raw/cast-button.prompt.txt;' + paint + 'raw/navy-panel.prompt.txt;' + paint + 'raw/generation-record.json',
    'pilot_review': prefix + 'build_review.py;' + paint + 'build_crypt.py;' + paint + 'raw/generation-record.json;' + prefix + 'ui/composition-metadata.json',
}
notes = {
    'pilot_shadeling': 'Retained r002 neutral/7parts/48-frame motion. 1024source/512export foot256,448; main384px canvas at254,92. No character repaint or anchor change.',
    'pilot_spark_tile': 'Retained r004 paint copied byte-identically into r006;512master/256export;24px caps. Latest board specimens omit names/values/cost/TEMP; states and undirected128unit edge ports stay separate. External cards retain details.',
    'pilot_button': 'Retained painted1024x256 layered sources and512x128 exports; primary56/18 and secondary38/20 slice caps unchanged. Remove/Rotate editing only; live labels and independent states. No theme import.',
    'pilot_review': 'Final-v2 clean board: BEGIN/END text only, no rune/path/End values, cost badges or TEMP. Corrected sideways-fork Split/upright-trident Join shared by board and toolbar. Complete crypt/UI, detailed hand/piles and forecast; native360 and state/type views updated.',
}
evidence = prefix + 'delivery.md;output/art/rc-011/r006/revision-validation.json;' + prefix + 'cross-screen-review.md'
out = [lines[0]]
changed = []
for line in lines[1:]:
    if not line.strip():
        out.append(line)
        continue
    row = dict(zip(header, next(csv.reader([line]))))
    ident = row['id']
    if ident not in sources:
        out.append(line)
        continue
    for rel in (sources[ident] + ';' + exports[ident] + ';' + generation[ident]).split(';'):
        assert (ROOT / rel).exists(), rel
    row.update(source_master_path=sources[ident], runtime_destination=exports[ident],
               current_paths=sources[ident], source_path_state='existing',
               runtime_path_state='source_only', readiness_status='source_ready',
               visual_direction_status='reference_guided', licence_status='unresolved')
    if evidence not in row['evidence_paths']:
        row['evidence_paths'] += ';' + evidence
    row['generation_reference'] = generation[ident]
    row['provenance'] = 'RC-011 r006: original editable SVG/text updates against approved final-v2; no new raster generation. Reuses r004 painted assets and r002 actor/font with original prompts, reference hashes and unknown model/seed preserved.'
    row['notes'] = 'r006 editable review; approval of supplied reference distinct from assistant review and unrecorded owner approval of reconstruction. No runtime/device/final-rights claim. ' + notes[ident]
    if ident == 'pilot_review':
        row['description'] = 'Complete crypt and supporting UI matching style pilot; final-v2 clean-board editable preview'
    if ident == 'pilot_spark_tile':
        row['required_states_variants'] = 'normal;selected;powered;unpowered;focused;invalid;unavailable;eligible;protected;four undirected rotations;clean board without labels/values/badges'
    buffer = io.StringIO(newline='')
    csv.writer(buffer, quoting=csv.QUOTE_ALL,
               lineterminator='\r\n' if line.endswith('\r\n') else '\n').writerow([row[k] for k in header])
    out.append(buffer.getvalue())
    changed.append(ident)
assert set(changed) == set(sources)
for before, after in zip(lines, out):
    if before != after:
        assert next(csv.reader([before]))[0] in sources
path.write_bytes(''.join(out).encode('utf-8'))
report = {
    'changed_ids': changed,
    'all_nonpilot_lines_preserved_byte_for_byte': True,
    'record_count': len(list(csv.DictReader(io.StringIO(''.join(out))))),
    'status': 'source_ready/source_only/reference_guided; no owner/runtime/device/rights approval inferred',
}
(ROOT / 'output/art/rc-011/r006/manifest-update.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
