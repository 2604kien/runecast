"""Read-only pilot artifact audit; writes only RC-011 review reports. No Git/Godot gameplay."""
from pathlib import Path
from PIL import Image
import hashlib,json,zipfile,xml.etree.ElementTree as ET,io,re,csv,sys,subprocess
from urllib.parse import unquote
P=Path(__file__).resolve().parent; ROOT=P.parents[1]; OUT=ROOT/'output/art/rc-011'
checks=[]
def check(ok,name,evidence):checks.append({'check':name,'result':'pass' if ok else 'FAIL','evidence':str(evidence)})
expected={'exports/shadeling.png':(512,512),'exports/spark_tile.png':(256,256),'exports/button_primary_normal.png':(512,128),'exports/button_secondary_normal.png':(512,128)}
for name,size in expected.items():
 im=Image.open(P/name);check(im.size==size and im.mode=='RGBA',f'dimensions and RGBA: {name}',{'size':im.size,'mode':im.mode});check(bool(im.info.get('icc_profile')),'sRGB profile: '+name,'ICC present' if im.info.get('icc_profile') else 'missing')
for path in (P/'exports/shadeling_parts').glob('*.png'):check(Image.open(path).size==(512,512),'shared full-canvas part '+path.name,path.relative_to(ROOT))
for name,size,count in [('shadeling/shadeling.ora',(1024,1024),7),('spark_tile/spark_tile.ora',(512,512),5),('button/button.ora',(1024,256),14)]:
 with zipfile.ZipFile(P/name) as z:
  xml=ET.fromstring(z.read('stack.xml'));layers=xml.findall('.//layer');digests=[]
  check(z.read('mimetype')==b'image/openraster','ORA mimetype '+name,name)
  check((int(xml.get('w')),int(xml.get('h')))==size,'ORA canvas '+name,name)
  check(len(layers)==count,'meaningful layer count '+name,len(layers))
  for layer in layers:
   data=z.read(layer.get('src'));im=Image.open(io.BytesIO(data)).convert('RGBA');digests.append(hashlib.sha256(im.tobytes()).hexdigest())
   check(im.size==size and im.getchannel('A').getbbox() is not None,'full-canvas nonempty layer '+layer.get('name'),name)
  check(len(set(digests))==count,'layers not duplicated flattened copies '+name,name)
  check(Image.open(io.BytesIO(z.read('mergedimage.png'))).size==size,'ORA merged image '+name,name)
for name,size in [('pilot-720x1600.png',(720,1600)),('pilot-450x1000.png',(450,1000)),('pilot-360x640.png',(360,640)),('pilot-360x640-controls.png',(360,640)),('pilot-360x640-inspector.png',(360,640)),('pilot-states.png',(1440,2280)),('pilot-type.png',(1100,1360))]:
 check((OUT/name).exists() and Image.open(OUT/name).size==size,'review dimensions '+name,size)
SVG='{http://www.w3.org/2000/svg}';XLINK='{http://www.w3.org/1999/xlink}'
for p in P.glob('pilot*.svg'):
 root=ET.parse(p).getroot();check(root.tag==SVG+'svg','editable SVG '+p.name,p.name)
 check(len(root.findall('.//'+SVG+'text'))>0,'editable text '+p.name,p.name)
 for element in root.iter():
  ref=element.get(XLINK+'href') or element.get('href')
  if ref and not ref.startswith('data:'):check((p.parent/ref).resolve().exists(),'linked resource '+ref,p.name)
glyph=ET.parse(P/'spark_tile/spark.svg').getroot()
check(glyph.get('viewBox')=='0 0 128 128','Spark128 viewBox','spark_tile/spark.svg')
check(not any(e.tag.split('}')[-1] in ['image','text','filter','use'] for e in glyph.iter()),'Spark no raster/font/filter/dependency','spark_tile/spark.svg')
geo=json.loads((P/'spark_tile/geometry-contract.json').read_text())
check(geo['ports']=={'N':[64,0],'E':[128,64],'S':[64,128],'W':[0,64]},'exact edge ports',geo['ports'])
points=[(0,64),(64,0),(128,64),(64,128)];outs=[(128,64),(64,128),(0,64),(64,0)]
for r in range(4):
 def turn(p):
  x,y=p
  for _ in range(r):x,y=128-y,x
  return x,y
 check(turn((0,64))==points[r] and turn((128,64))==outs[r],f'W-E graph rotation {r}',{'input':points[r],'output':outs[r]})
meta=json.loads((P/'shadeling/metadata.json').read_text())
check(meta['source_foot']==[512,896] and meta['export_foot']==[256,448] and meta['shared_origin']==[0,0],'common anchors/origin','shadeling/metadata.json')
check(meta['envelope_pass'],'motion inside32..480','shadeling/metadata.json')
frames=list((OUT/'pilot-motion-frames').glob('*.png'));check(len(frames)==48,'48-frame authoritative sequence',len(frames))
timing=json.loads((OUT/'pilot-motion-timing.json').read_text());check(timing['fps']==8 and len({f['frame'] for f in timing['frames']})==48 and len(timing['frames'])==96,'6 second timing manifest with paired reduced-motion records','pilot-motion-timing.json')
check((ROOT/'source-assets/.gdignore').exists() and (ROOT/'output/.gdignore').exists(),'source and review import exclusion','.gdignore files; export presets not changed')
for p in P.rglob('*.md'):
 for ref in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8-sig')):
  if re.match(r'[A-Za-z][A-Za-z0-9+.-]*:',ref):continue
  filename,_,anchor=unquote(ref).partition('#');target=(p.parent/filename).resolve() if filename else p
  ok=target.exists()
  if ok and anchor and target.suffix=='.md':
   content=target.read_text(encoding='utf-8-sig')
   titles=re.findall(r'^#{1,6}\s+(.+)$',content,re.M)
   anchors={re.sub(r'[^\w\- ]','',t.lower()).replace(' ','-') for t in titles}
   anchors.update(re.findall(r'<a\s+(?:id|name)="([^"]+)"',content))
   ok=anchor in anchors
  check(ok,'delivery link '+ref,p.relative_to(ROOT))
pngs=list((P/'exports').rglob('*.png'))+list((P/'button/overlays').glob('*.png'))
memory=[]
for p in pngs:
 im=Image.open(p);memory.append({'path':p.relative_to(ROOT).as_posix(),'size':im.size,'assumed_format':'RGBA8','decoded_bytes':im.width*im.height*4})
svgpaths=list((P/'exports').rglob('*.svg'))
for p in svgpaths:memory.append({'path':p.relative_to(ROOT).as_posix(),'size':[128,128],'assumed_format':'RGBA8 rasterization at128 square; estimate, not imported','decoded_bytes':128*128*4})
total=sum(v['decoded_bytes'] for v in memory)
report={'task':'RC-011','date':'2026-10-11','result':'PASS' if all(c['result']=='pass' for c in checks) else 'FAIL','checks':checks,'check_count':len(checks),'decoded_memory':{'all_candidate_textures_bytes':total,'all_candidate_textures_MiB':total/1048576,'includes':'neutral plus all seven parts simultaneously, both button bases, all six optional raster state overlays, tile, all10SVG candidates at128','excludes':'ORA/raw generations/review PNGs/fonts/engine/render buffers; these are not runtime resources','items':memory},'limits':'Artifact structure and desktop preview evidence only; no owner approval, Godot pilot imports, gameplay integration, final rights clearance or device verification.'}
(OUT/'pilot-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'result':report['result'],'checks':len(checks),'failures':[c for c in checks if c['result']!='pass'],'memory_MiB':total/1048576},indent=2))
raise SystemExit(report['result']!='PASS')
