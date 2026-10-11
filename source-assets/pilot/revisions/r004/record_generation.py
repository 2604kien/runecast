"""Record all retained built-in image generation outputs without inventing metadata."""
from pathlib import Path
import hashlib,json
P=Path(__file__).resolve().parent
file=P/'raw/generation-record.json'
m=json.loads(file.read_text())
extra=[('navy-panel','exec-5449d147-7276-42db-a728-5cc07aa24d90.png'),('cast-button','exec-3d688422-86ba-403e-9163-c97b1789b827.png')]
for name,original in extra:
    if not any(x['asset']==name+'.png' for x in m['records']):
        m['records'].append({'asset':name+'.png','prompt':name+'.prompt.txt','original_output':'C:/Users/nguye/.codex/generated_images/01a125b7-21db-7683-ac68-ba49d0b1e8d3/'+original,'selected':True,'transparent_background':True})
for rec in m['records']:
    for key in ['asset','prompt']:
        rec[key+'_sha256']=hashlib.sha256((P/'raw'/rec[key]).read_bytes()).hexdigest()
file.write_text(json.dumps(m,indent=2)+'\n',encoding='utf-8')
print('Recorded',len(m['records']),'retained generations and prompts')
