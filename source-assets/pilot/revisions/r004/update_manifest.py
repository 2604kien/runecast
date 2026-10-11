"""Reconcile the four pilot records only; preserve all other CSV bytes."""
from pathlib import Path
import csv,io,json
P=Path(__file__).resolve().parent;ROOT=P.parents[3]
path=ROOT/'docs/asset-inventory.csv'
before=path.read_bytes();lines=before.decode('utf-8').splitlines(keepends=True)
header=next(csv.reader([lines[0]]));prefix='source-assets/pilot/revisions/r004/'
sources={
 'pilot_shadeling':'source-assets/pilot/revisions/r002/shadeling.ora',
 'pilot_spark_tile':prefix+'ui/painted_tile.ora;'+prefix+'ui/spark.svg',
 'pilot_button':prefix+'ui/cast-button.ora;'+prefix+'ui/navy-panel.ora',
 'pilot_review':prefix+'pilot_review.svg;'+prefix+'crypt/crypt.ora'}
exports={
 'pilot_shadeling':'source-assets/pilot/revisions/r002/exports/shadeling.png;source-assets/pilot/revisions/r002/exports/shadeling_parts/',
 'pilot_spark_tile':prefix+'exports/spark_tile.png;'+prefix+'ui/spark.svg',
 'pilot_button':prefix+'exports/button_primary.png;'+prefix+'exports/button_secondary.png',
 'pilot_review':'output/art/rc-011/r004/'}
notes={
 'pilot_shadeling':'Selected r002 neutral/7parts/48-frame motion retained;1024source/512export foot256,448. r004 main displays384px canvas at254,92 (foot446,428). Lean transform feasibility only; final poses/events remain RC-014/017.',
 'pilot_spark_tile':'New painted512master/256export;24px slice caps replace insufficient16px proposal. Complementary stoneface/goldrim with hidden color variants; live labels/TEMP and undirected128unit edge ports stay separate;24/32/48glyphs and137/72cells inspected.',
 'pilot_button':'New painted1024x256 primary/secondary layered sources and512x128reviewexports. Live-size nine-slicing preserves painted endplates; Cast cap proportional to height instead of24px draft. Live labels and independent state geometry; no theme import.',
 'pilot_review':'Expanded complete crypt/supporting UI;841/720/450 fullviews, native360 scrollstudy, current states/type, exact generation prompts. Complete undirected illustrative route, Remove/Rotate, detailed hand/piles and forecast. Crypt7semanticlayers; no hidden-area parallax claim.'}
new_evidence=prefix+'delivery.md;output/art/rc-011/r004/revision-validation.json;'+prefix+'cross-screen-review.md'
new_generation={
 'pilot_shadeling':'source-assets/pilot/revisions/r002/raw/shadeling.prompt.txt;source-assets/pilot/revisions/r002/metadata.json',
 'pilot_spark_tile':prefix+'raw/empty-tile.prompt.txt;'+prefix+'ui/painted-frame-metadata.json',
 'pilot_button':prefix+'raw/cast-button.prompt.txt;'+prefix+'raw/navy-panel.prompt.txt;'+prefix+'raw/generation-record.json',
 'pilot_review':prefix+'build_review.py;'+prefix+'build_crypt.py;'+prefix+'raw/generation-record.json;'+prefix+'ui/composition-metadata.json'}
out=[lines[0]];changed=[];unchanged=True
for line in lines[1:]:
 if not line.strip():out.append(line);continue
 row=dict(zip(header,next(csv.reader([line]))));ident=row['id']
 if ident not in sources:out.append(line);continue
 for rel in (sources[ident]+';'+exports[ident]).split(';'):
  assert (ROOT/rel).exists(),rel
 row.update(source_master_path=sources[ident],runtime_destination=exports[ident],current_paths=sources[ident],source_path_state='existing',runtime_path_state='source_only',readiness_status='source_ready',visual_direction_status='reference_guided',licence_status='unresolved')
 if new_evidence not in row['evidence_paths']:row['evidence_paths']+=';'+new_evidence
 row['generation_reference']=new_generation[ident]
 row['provenance']='RC-011 r004: built-in imagegen painted source with exact retained prompts and raw output; genuine semantic separation and original editable SVG geometry; retained r002 character/font provenance; model version and seed not exposed'
 row['notes']='r004 complete expanded source/review pack; assistant technical/art-direction review separate from unrecorded owner approval. Prior r001/r002 full previews remain rejected/superseded history; approved reference unchanged. No runtime/device/final-rights claim. '+notes[ident]
 if ident=='pilot_review':row['description']='Complete crypt and supporting UI matching style pilot; editable gameplay preview'
 if ident=='pilot_spark_tile':row['required_states_variants']='normal;selected;temporary;powered;unpowered;focused;invalid;unavailable;eligible;protected;four undirected rotations'
 b=io.StringIO(newline='');csv.writer(b,quoting=csv.QUOTE_ALL,lineterminator='\r\n' if line.endswith('\r\n') else '\n').writerow([row[k] for k in header]);out.append(b.getvalue());changed.append(ident)
assert set(changed)==set(sources)
for a,b in zip(lines,out):
 if a!=b:
  assert next(csv.reader([a]))[0] in sources
path.write_bytes(''.join(out).encode('utf-8'))
report={'changed_ids':changed,'all_nonpilot_lines_preserved_byte_for_byte':True,'record_count':len(list(csv.DictReader(io.StringIO(''.join(out))))),'status':'source_ready/source_only/reference_guided; review production only; no owner/runtime/device/rights approval inferred'}
(ROOT/'output/art/rc-011/r004/manifest-update.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
