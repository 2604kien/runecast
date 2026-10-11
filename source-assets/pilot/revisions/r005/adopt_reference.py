"""Adopt the owner's clean-board final visual; preserve all earlier artwork."""
from pathlib import Path
from PIL import Image
import csv,hashlib,io,json,shutil,subprocess,sys
P=Path(__file__).resolve().parent;ROOT=P.parents[3];OUT=ROOT/'output/art/rc-011/r005'
OUT.mkdir(parents=True,exist_ok=True)
SRC=Path('C:/Users/nguye/AppData/Local/Temp/codex-clipboard-f1aabbea-227e-40bb-a12a-a253270dbb34.png')
CANON=ROOT/'output/imagegen/approved/combat-final-v2-clean-board.png'
EXPECTED='ad5e7429a79c53d65c6ef00e5094b83b58738b10715a2478c64230bdbc6688ac'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
snapshot_file=OUT/'prior-artwork-hashes.json'
if not snapshot_file.exists():
    dirs=['output/imagegen','source-assets/pilot/revisions/r004','output/art/rc-011/r004']
    files=sorted({p for d in dirs for p in (ROOT/d).rglob('*') if p.is_file()})
    snapshot_file.write_text(json.dumps({p.relative_to(ROOT).as_posix():sha(p) for p in files},indent=2)+'\n')
snapshot=json.loads(snapshot_file.read_text())
source=SRC if SRC.exists() else CANON
assert sha(source)==EXPECTED,'Unexpected source attachment'
if CANON.exists():assert sha(CANON)==EXPECTED,'Preserve unexpected canonical file'
else:shutil.copy2(source,CANON)
im=Image.open(CANON);v10=Image.open(ROOT/'output/imagegen/rune-cast-gameplay-reference-v10-clean-board.png')
pixels_same=im.size==v10.size and im.convert('RGBA').tobytes()==v10.convert('RGBA').tobytes()
manifest=ROOT/'docs/asset-inventory.csv';lines=manifest.read_bytes().decode().splitlines(keepends=True)
header=next(csv.reader([lines[0]]));out=[lines[0]];changed=[]
prompts=sorted((ROOT/'output/imagegen').glob('*.prompt.txt'))
assert all(p.with_name(p.name.replace('.prompt.txt','.png')).exists() for p in prompts)
for line in lines[1:]:
    if not line.strip():out.append(line);continue
    row=dict(zip(header,next(csv.reader([line]))));key=row['id']
    if key not in ['reference_combat','reference_history']:out.append(line);continue
    if key=='reference_combat':
        row.update(description='Owner-approved final gameplay v2; clean board and corrected Split/Join',source_master_path=CANON.relative_to(ROOT).as_posix(),current_paths=CANON.relative_to(ROOT).as_posix(),required_states_variants='complete crypt/UI;undirected;Begin/End labels only on board;no board values/cost/TEMP;sideways-fork Split;upright-trident Join;Remove/Rotate;piles;forecast',provenance='Exact owner-supplied PNG; explicit final gameplay approval; unchanged841x1870pixels; SHA256 in r005 report',generation_reference='User attachment codex-clipboard-f1aabbea-227e-40bb-a12a-a253270dbb34.png;no new generation or retouching;v10 pixel comparison recorded',evidence_paths='docs/gameplay-visual-contract.md;docs/visual-reference.md;source-assets/pilot/revisions/r005/delivery.md;output/art/rc-011/r005/reference-validation.json',notes='Supersedes combat-final.png board labels/values and Split/Join silhouettes; previous approved images and pilot sources preserved. Board glyphs/paths remain; hand, toolbar and external info retain text/numbers. Approval is for this supplied flattened reference, not r004 reconstruction or runtime.')
    else:
        row.update(description=f'{len(prompts)} preserved generated studies and paired prompts',runtime_use=f'{len(prompts)} preserved generated studies and paired prompts',format=f'{len(prompts)} PNG + {len(prompts)} prompt TXT',required_states_variants='Combat v1-v10;Home v1;Map v1-v2;Menu v1-v2',generation_reference=f'output/imagegen/*.prompt.txt ({len(prompts)} preserved pairs;final approval uses exact user attachment)',notes='All original studies and prompts preserved;v8 removes path/End values,v9 correctsSplit/Join,v10cleansboardnames/costs/TEMP. Current official reference is separate exact owner attachment; no older prompt overrides latest approval.')
    b=io.StringIO(newline='');csv.writer(b,quoting=csv.QUOTE_ALL,lineterminator='\r\n' if line.endswith('\r\n') else '\n').writerow([row[k] for k in header]);out.append(b.getvalue());changed.append(key)
assert set(changed)=={'reference_combat','reference_history'}
assert all(a==b for a,b in zip(lines,out) if not a.startswith('"reference_combat"') and not a.startswith('"reference_history"'))
manifest.write_bytes(''.join(out).encode())
protected=json.loads((ROOT/'output/qa/rc-010/preservation-baseline.json').read_text())
bad=[r['path'] for r in protected if not (ROOT/r['path']).is_file() or sha(ROOT/r['path'])!=r['sha256']]
old_changed=[p for p,h in snapshot.items() if not (ROOT/p).is_file() or sha(ROOT/p)!=h]
assert not bad and not old_changed,(bad,old_changed)
report={'result':'PASS','source_attachment':str(SRC),'canonical':CANON.relative_to(ROOT).as_posix(),'sha256':sha(CANON),'attachment_bytes_identical':sha(CANON)==EXPECTED,'size':list(im.size),'mode':im.mode,'pixel_sha256':hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest(),'v10_pixels_identical':pixels_same,'new_generation':False,'new_image_edit':False,'approved_by':'User explicitly requested this supplied image as approved final gameplay','changes':['Board labels only BEGIN and END','No rune/branch/End values, cost badges or TEMP on board','Sideways-fork Split and upright-trident Join on board and toolbar','Hand/toolbar/info values remain outside board'],'manifest_changed_ids':changed,'other_manifest_rows_preserved':True,'historical_prompt_pairs':len(prompts),'original_protected_files':len(protected),'original_protected_changes':bad,'prior_artwork_files':len(snapshot),'prior_artwork_changes':old_changed,'runtime_changed':False,'scope':'Final reference adoption; no new editable pilot or runtime implementation claim'}
(OUT/'reference-validation.json').write_text(json.dumps(report,indent=2)+'\n')
historical=ROOT/'output/qa/rc-010/validation-report.json';saved=historical.read_bytes()
plan_path=OUT/'asset-plan-validation.json'
if not plan_path.exists():
    plan_path.write_text(json.dumps({'result':'PENDING','scope':'Self-referenced report path reserved before validator; replaced immediately by actual result'})+'\n')
try:
    result=subprocess.run([sys.executable,str(ROOT/'tools/validate_asset_plan.py')],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
    plan=json.loads(result.stdout);(OUT/'asset-plan-validation.json').write_text(json.dumps(plan,indent=2)+'\n')
finally:historical.write_bytes(saved)
assert result.returncode==0,plan.get('errors')
assert historical.read_bytes()==saved
print(json.dumps({k:report[k] for k in ['result','size','sha256','attachment_bytes_identical','v10_pixels_identical','historical_prompt_pairs','original_protected_files','prior_artwork_files']},indent=2))
print('Asset-plan checks:',sum(plan['checks_by_family'].values()),plan['result'])
