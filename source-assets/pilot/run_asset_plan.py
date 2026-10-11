"""Run the existing validator and preserve its historical RC-010 report byte-for-byte."""
from pathlib import Path
import subprocess,sys,json
ROOT=Path(__file__).resolve().parents[2]
historical=ROOT/'output/qa/rc-010/validation-report.json'
original=historical.read_bytes()
try:
 result=subprocess.run([sys.executable,str(ROOT/'tools/validate_asset_plan.py')],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
 data=json.loads(result.stdout)
 (ROOT/'output/art/rc-011/asset-plan-validation.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
 print(json.dumps({'result':data['result'],'errors':data['errors'],'checks':sum(data['checks_by_family'].values()),'protected_files':data['protected_files'],'protected_changes':data['protected_changes'],'historical_report_preserved':True},indent=2))
finally:
 historical.write_bytes(original)
raise SystemExit(result.returncode)
