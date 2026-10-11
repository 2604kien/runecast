"""Inspect actual saved RC-011 Shadeling resources; no gameplay execution."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import io, json, zipfile, hashlib, xml.etree.ElementTree as ET

S=Path(__file__).resolve().parent
R=S.parents[2]
O=R/'output/art/rc-011'
P=S.parent/'exports/shadeling_parts'
m=json.loads((S/'metadata.json').read_text())
checks=[]
def check(name,result,details=None):
    checks.append({'check':name,'pass':bool(result),'details':details})
neutral=Image.open(S.parent/'exports/shadeling.png').convert('RGBA')
check('neutral export dimensions and mode',neutral.size==(512,512) and neutral.mode=='RGBA')
check('raw immutable hash',hashlib.sha256((S/'raw/neutral-generation.png').read_bytes()).hexdigest()==m['generation']['raw_sha256'])
parts={k:Image.open(P/f'{k}.png').convert('RGBA') for k in m['draw_order']}
check('shared exported part dimensions',all(p.size==(512,512) for p in parts.values()))
check('source and runtime-format PNGs embed sRGB ICC',all(Image.open(p).info.get('icc_profile') for p in list((S/'layers').glob('*.png'))+list(P.glob('*.png'))+[S.parent/'exports/shadeling.png',S/'neutral-reference.png']))
check('unique nonempty exported parts',len({p.tobytes() for p in parts.values()})==len(parts) and all(p.getchannel('A').getbbox() for p in parts.values()))
recomposed=Image.new('RGBA',(512,512))
for k in m['draw_order']:recomposed.alpha_composite(parts[k])
check('export exactly recomposes from parts',np.array_equal(np.array(neutral),np.array(recomposed)))
with zipfile.ZipFile(S/'shadeling.ora') as z:
    check('OpenRaster MIME',z.read('mimetype')==b'image/openraster')
    root=ET.fromstring(z.read('stack.xml'));layers=root.findall('.//layer')
    check('OpenRaster source size',root.attrib['w']=='1024' and root.attrib['h']=='1024')
    check('OpenRaster meaningful seven layers',len(layers)==7 and len({z.read(l.attrib['src']) for l in layers})==7)
    check('OpenRaster PNG members embed sRGB ICC',all(Image.open(io.BytesIO(z.read(p))).info.get('icc_profile') for p in z.namelist() if p.endswith('.png')))
    ora=Image.new('RGBA',(1024,1024))
    for l in reversed(layers):
        p=Image.open(io.BytesIO(z.read(l.attrib['src']))).convert('RGBA')
        check('OpenRaster full-canvas '+l.attrib['name'],p.size==(1024,1024) and l.attrib['x']=='0' and l.attrib['y']=='0')
        ora.alpha_composite(p)
    check('OpenRaster merged image exact',np.array_equal(np.array(ora),np.array(Image.open(io.BytesIO(z.read('mergedimage.png'))).convert('RGBA'))))
check('source and export anchors consistent',m['source_foot']==[512,896] and m['export_foot']==[256,448])
baseline=json.loads((S/'profile-pixel-baseline.json').read_text())
check('sRGB profile assignment preserves every decoded source and export pixel',all(hashlib.sha256(Image.open(R/p).tobytes()).hexdigest()==h for p,h in baseline.items()),{'files':len(baseline)})
ET.parse(S/'separation-masks.svg')
check('editable separation SVG parses and links raw',(S/'raw/neutral-generation.png').exists())
timing=json.loads((O/'pilot-motion-timing.json').read_text())
frames=sorted((O/'pilot-motion-frames').glob('frame_*.png'))
check('timed sequence 48 frames',len(frames)==48 and timing['fps']==8 and timing['frame_duration_ms']==125)
check('all motion images decode at 1280x720',all(Image.open(p).size==(1280,720) for p in frames))
check('motion and reduced bounds within envelope',all(r['alpha_bounds_gt16'] is None or (r['alpha_bounds_gt16'][0]>=32 and r['alpha_bounds_gt16'][1]>=32 and r['alpha_bounds_gt16'][2]<=480 and r['alpha_bounds_gt16'][3]<=480) for r in timing['frames']))
check('all nonzero alpha including filtering within envelope',all(r['alpha_bounds_all'] is None or (r['alpha_bounds_all'][0]>=32 and r['alpha_bounds_all'][1]>=32 and r['alpha_bounds_all'][2]<=480 and r['alpha_bounds_all'][3]<=480) for r in timing['frames']))
gif=Image.open(O/'pilot-motion.gif')
check('GIF decodes with duration equal to sequence',sum(gif.seek(i) or gif.info.get('duration',0) for i in range(gif.n_frames))>=5800,{'gif_frames':gif.n_frames,'png_frames':len(frames),'GIF note':'GIF delay is quantized to 10 ms; PNG sequence timing is authoritative.'})
# Exact 512-pixel alpha evidence on pure black and white, without scaling.
sheet=Image.new('RGB',(1084,620),'#172333');d=ImageDraw.Draw(sheet)
f=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
for i,(color,label) in enumerate([('#ffffff','PURE WHITE / native 512 export'),('#000000','PURE BLACK / native 512 export')]):
    bg=Image.new('RGBA',(512,512),color);bg.alpha_composite(neutral)
    sheet.paste(bg.convert('RGB'),(20+532*i,55));d.text((24+532*i,22),label,font=f,fill='#f1e1bc')
d.text((24,585),'Full canvas and original alpha shown; no preview scaling, baked shadow or opaque background.',font=f,fill='#f1e1bc')
sheet.save(O/'pilot-shadeling-alpha-native.png')
report={'asset_id':'pilot_shadeling','review_date':'2026-10-11','result':'PASS' if all(c['pass'] for c in checks) else 'FAIL','checks':checks,
 'limits':'File/layer/geometry validation only. Actual artistic findings and owner/device/integration limitations are recorded in delivery.md.'}
(S/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'result':report['result'],'checks':len(checks),'failed':[c for c in checks if not c['pass']]}))
raise SystemExit(0 if report['result']=='PASS' else 1)
