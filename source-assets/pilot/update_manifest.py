"""Reconcile only the four RC-011 pilot CSV records; preserve every other line."""
from pathlib import Path
import csv,io,json
ROOT=Path(__file__).resolve().parents[2];p=ROOT/'docs/asset-inventory.csv'
original=p.read_bytes();lines=original.decode('utf-8').splitlines(keepends=True)
header=next(csv.reader([lines[0]]));changed=[];output=[lines[0]]
evidence={
 'pilot_shadeling':'source-assets/pilot/delivery.md;source-assets/pilot/shadeling/validation.json;output/art/rc-011/pilot-shadeling-alpha-native.png;output/art/rc-011/pilot-motion-sheet.png',
 'pilot_spark_tile':'source-assets/pilot/delivery.md;source-assets/pilot/spark_tile/geometry-checks.json;output/art/rc-011/pilot-glyphs.png;output/art/rc-011/pilot-states.png',
 'pilot_button':'source-assets/pilot/delivery.md;source-assets/pilot/button/validation.json;output/art/rc-011/pilot-states.png',
 'pilot_review':'source-assets/pilot/delivery.md;output/art/rc-011/pilot-validation.json;output/art/rc-011/pilot-720x1600.png;output/art/rc-011/pilot-450x1000.png;output/art/rc-011/pilot-360x640.png;output/art/rc-011/pilot-type.png;output/art/rc-011/pilot-motion-timing.json'}
generation={
 'pilot_shadeling':'source-assets/pilot/shadeling/raw/neutral.prompt.txt;source-assets/pilot/shadeling/metadata.json',
 'pilot_spark_tile':'source-assets/pilot/spark_tile/raw/navy_material_r001.prompt.txt;source-assets/pilot/spark_tile/raw/navy_material_r001.metadata.json;source-assets/pilot/spark_tile/geometry-contract.json',
 'pilot_button':'source-assets/pilot/button/raw/turquoise_material_r001.prompt.txt;source-assets/pilot/button/raw/turquoise_material_r001.metadata.json;source-assets/pilot/button/material_metadata.json',
 'pilot_review':'source-assets/pilot/build_review.py;source-assets/pilot/render_review.cjs;source-assets/pilot/font-direction.md'}
for line in lines[1:]:
 if not line.strip():output.append(line);continue
 fields=next(csv.reader([line]));row=dict(zip(header,fields));ident=row['id']
 if ident not in evidence:output.append(line);continue
 row.update(source_path_state='existing',readiness_status='source_ready',runtime_path_state='source_only',visual_direction_status='reference_guided',licence_status='unresolved',evidence_paths=evidence[ident],generation_reference=generation[ident],current_paths=row['source_master_path'])
 revision='source-assets/pilot/revisions/r002/'
 row['evidence_paths']+=';'+revision+'delivery.md;output/art/rc-011/r002/revision-validation.json'
 row['current_paths']+=';'+revision+({'pilot_shadeling':'shadeling.ora','pilot_spark_tile':'ui/tile_spark.ora','pilot_button':'ui/button_cast.ora','pilot_review':'pilot_review.svg'}[ident])
 row['generation_reference']+=';'+revision+({'pilot_shadeling':'raw/shadeling.prompt.txt;'+revision+'metadata.json','pilot_spark_tile':'type-geometry/spark-geometry-contract.json','pilot_button':'ui/candidate-metadata.json','pilot_review':'build_review.py;'+revision+'type-geometry/font-provenance.json'}[ident])
 row['provenance']='RC-011 r001: built-in imagegen raw paint with exact prompts and available metadata; original editable geometry/separation; model version unknown' if ident!='pilot_review' else 'RC-011 r001: original editable SVG composition and deterministic rendering; actual engine fallback specimen; linked source/provenance records'
 common='r001 owner-rejected for visual fidelity on 2026-10-11; preserved as history. r002 correction exists with actual serif and revised art;509structural checks pass; full-reference matching remains revise, not an accepted production baseline. No Godot import/integration/device or final rights claim. '
 row['notes']=common+({'pilot_shadeling':'r002 seven layers;512 canvas foot256,448;display0.64 replaces0.46;48-frame PNG/GIF motion; final pose work RC-014/017.',
 'pilot_spark_tile':'r002 amber face and80pxglyph at137cells/34px at72;1.5/2.5warm glyph edges replace provisional8/6;128viewBox/exactports/16slices retained; live labels/TEMP separate.',
 'pilot_button':'r002 broad gold bevels; standard24LR/20TBslices retained; pointed Cast uses responsivevector geometry beyond24px caps;sharedstates.',
 'pilot_review':'r002720/450/native360 plus companions/states/type/motion; actual NotoSerif2.015 andOFL acquired forreview; environment/nonSpark blockouts remain explicit.'}[ident])
 buf=io.StringIO(newline='');writer=csv.writer(buf,quoting=csv.QUOTE_ALL,lineterminator='\r\n' if line.endswith('\r\n') else '\n');writer.writerow([row[k] for k in header]);output.append(buf.getvalue());changed.append(ident)
assert sorted(changed)==sorted(evidence)
p.write_bytes(''.join(output).encode('utf-8'))
(ROOT/'output/art/rc-011/manifest-update.json').write_text(json.dumps({'changed_ids':changed,'nonpilot_lines_preserved_byte_for_byte':all(a==b for a,b in zip(lines,output) if not any('"'+ident+'"' in a.split(',')[0] for ident in evidence)),'status':'source_ready; source_only; reference_guided; licence unresolved; owner rejected r001 visual fidelity; revision required'},indent=2)+'\n')
print('Reconciled only: '+', '.join(changed))
