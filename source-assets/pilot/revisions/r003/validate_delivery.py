"""Run the asset-plan checks without overwriting historical review reports."""
from pathlib import Path
import subprocess,sys,json,re
from urllib.parse import unquote
P=Path(__file__).resolve().parent;ROOT=P.parents[3];OUT=ROOT/'output/art/rc-011/r003'
historical=ROOT/'output/qa/rc-010/validation-report.json';original=historical.read_bytes()
try:
    result=subprocess.run([sys.executable,str(ROOT/'tools/validate_asset_plan.py')],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
    if not result.stdout.strip():raise RuntimeError(result.stderr)
    report=json.loads(result.stdout)
    (OUT/'asset-plan-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
finally:
    historical.write_bytes(original)
links=[]
for doc in [P/'delivery.md',ROOT/'docs/gameplay-visual-contract.md']:
    for ref in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf-8')):
        if re.match(r'[a-z]+:',ref):continue
        target=(doc.parent/unquote(ref.split('#')[0])).resolve()
        links.append({'source':str(doc.relative_to(ROOT)),'target':ref,'exists':target.exists()})
summary={'result':'PASS' if result.returncode==0 and all(x['exists'] for x in links) else 'FAIL','asset_plan_checks':sum(report['checks_by_family'].values()),'historical_prompt_pairs':report['historical_prompt_pairs'],'protected_files':report['protected_files'],'protected_changes':report['protected_changes'],'historical_rc010_report_preserved':historical.read_bytes()==original,'additional_local_links':links,'asset_plan_errors':report['errors'],'scope':'Image/manifest/document checks; no runtime behavior or production layer claim'}
(OUT/'delivery-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k!='additional_local_links'},indent=2))
raise SystemExit(summary['result']!='PASS')
