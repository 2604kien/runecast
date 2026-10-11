"""Adopt the owner-supplied complete reference; no image editing or runtime writes."""
from pathlib import Path
from PIL import Image
import csv,io,hashlib,json,shutil
P=Path(__file__).resolve().parent;ROOT=P.parents[3]
SOURCE=Path('C:/Users/nguye/AppData/Local/Temp/codex-clipboard-3239e11b-675a-4bd5-baae-050d1ecc125b.png')
CANON=ROOT/'output/imagegen/approved/combat-final.png'
COPY=ROOT/'output/art/rc-011/r003/gameplay-final.png'
EXPECTED='c753021b16fbe7af9fa57cadae5d32525f9283dbc1da0af883b8614965af2da4'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
source=SOURCE if SOURCE.exists() else CANON
assert sha(source)==EXPECTED,'Do not adopt an unverified replacement attachment'
for dest in [CANON,COPY]:
    dest.parent.mkdir(parents=True,exist_ok=True)
    if dest.exists():assert sha(dest)==EXPECTED,'Preserve any unexpected existing revision'
    elif dest!=source:shutil.copy2(source,dest)

manifest=ROOT/'docs/asset-inventory.csv';before=manifest.read_bytes();lines=before.decode('utf-8').splitlines(keepends=True);header=next(csv.reader([lines[0]]));out=[lines[0]];changed=[]
for line in lines[1:]:
    if not line.strip():out.append(line);continue
    row=dict(zip(header,next(csv.reader([line]))));ident=row['id']
    if ident not in ['reference_combat','reference_history']:out.append(line);continue
    if ident=='reference_combat':
        row.update(description='Official final complete gameplay visual; owner approved October11 2026',runtime_use='Authoritative complete Combat appearance and undirected visual contract',source_master_path='output/imagegen/approved/combat-final.png',required_states_variants='complete crypt and supporting UI;undirected connections;Remove and Rotate;draw/discard;forecast above Cast',provenance='Exact user-supplied PNG; explicit request to make official October11 2026; unchanged841x1870pixels; file SHA256 recorded in r003 delivery',generation_reference='User attachment codex-clipboard-3239e11b-675a-4bd5-baae-050d1ecc125b.png;decoded pixels match preserved v7Remove;no new generation or image edit',evidence_paths='docs/gameplay-visual-contract.md;docs/visual-reference.md;source-assets/pilot/revisions/r003/delivery.md;output/art/rc-011/r003/final-reference-validation.json',current_paths='output/imagegen/approved/combat-final.png',notes='Supersedes October8 Combat visually;old approved/combat.png preserved;full painted reference without placeholders. Design changes accepted;runtime stillolderimplementation. BOSS/infinity/examplevalues do not establish additional mechanics. Reference only, not layered production art.')
    else:
        row.update(description='Twelve preserved generated studies and paired prompt text',runtime_use='Twelve preserved generated studies and paired prompt text',format='12 PNG + 12 prompt TXT',required_states_variants='combat v1-v7;Home v1;Map v1-v2;Menu v1-v2',generation_reference='output/imagegen/*.prompt.txt (12 preserved historical prompts;final approval uses exact user attachment)',notes='Preserve all originals and prompts;v6 adds undirected circuit/fullhand/piles/forecast,v7 replacesUndo withRemove;earlier prompts do not override final owner contract')
    buf=io.StringIO(newline='');csv.writer(buf,quoting=csv.QUOTE_ALL,lineterminator='\r\n' if line.endswith('\r\n') else '\n').writerow([row[k] for k in header]);out.append(buf.getvalue());changed.append(ident)
assert set(changed)=={'reference_combat','reference_history'}
manifest.write_bytes(''.join(out).encode('utf-8'))
protected=json.loads((ROOT/'output/qa/rc-010/preservation-baseline.json').read_text())
changes=[r['path'] for r in protected if not (ROOT/r['path']).exists() or sha(ROOT/r['path'])!=r['sha256']]
assert not changes,changes
im=Image.open(CANON);v7=ROOT/'output/imagegen/rune-cast-gameplay-reference-v7-remove.png'
same_pixels=im.size==Image.open(v7).size and im.convert('RGBA').tobytes()==Image.open(v7).convert('RGBA').tobytes()
report={'result':'PASS','date':'2026-10-11','artifact_kind':'owner-approved flattened final visual reference','source_attachment':str(SOURCE),'canonical_path':str(CANON.relative_to(ROOT)),'review_path':str(COPY.relative_to(ROOT)),'size':list(im.size),'mode':im.mode,'attachment_sha256':EXPECTED,'canonical_sha256':sha(CANON),'review_sha256':sha(COPY),'copies_byte_identical':sha(CANON)==sha(COPY)==EXPECTED,'pixel_sha256':hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest(),'v7_decoded_pixels_identical':same_pixels,'v7_sha256':sha(v7),'new_generation':False,'new_image_edit':False,'visual_checks':{'undirected_board_and_wiring_symbols':'present; no circuit arrowheads','only_remove_rotate_editing_actions':'present; other requested editing actions absent','draw_and_discard':'present on left/right of hand','forecast_above_cast':'present;damage/shield/cost/incoming','complete_crypt_and_supporting_ui':'present; no visible placeholders'},'approval_evidence':'User explicitly requested this supplied image become the official final gameplay visual and expanded full-preview scope','runtime_changed':False,'protected_files_checked':len(protected),'protected_changes':changes,'manifest_changed_ids':changed,'all_other_manifest_rows_preserved':all(a==b for a,b in zip(lines,out) if not a.startswith('"reference_combat"') and not a.startswith('"reference_history"'))}
assert report['copies_byte_identical'] and report['all_other_manifest_rows_preserved']
(COPY.parent/'final-reference-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:report[k] for k in ['result','size','copies_byte_identical','v7_decoded_pixels_identical','protected_files_checked','protected_changes','manifest_changed_ids']},indent=2))
