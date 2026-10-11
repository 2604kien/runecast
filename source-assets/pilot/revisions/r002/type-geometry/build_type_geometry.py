"""Isolated r002 reference-matching type and editable Spark study. No runtime writes."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib, json, math, struct, xml.etree.ElementTree as ET

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
OUT=ROOT/'output/art/rc-011/r002/type-geometry'
OUT.mkdir(parents=True,exist_ok=True)
FONT=HERE/'fonts/NotoSerif-Variable.ttf'

def serif(size,weight=600):
    font=ImageFont.truetype(str(FONT),size)
    font.set_variation_by_axes([weight,100])
    return font

def metadata_names(path):
    data=path.read_bytes(); tables={}
    for i in range(struct.unpack_from('>H',data,4)[0]):
        tag,check,offset,length=struct.unpack_from('>4sIII',data,12+i*16)
        tables[tag]=(offset,length)
    p,_=tables[b'name']; fmt,count,strings=struct.unpack_from('>HHH',data,p)
    names={}
    for i in range(count):
        platform,encoding,language,ident,n,off=struct.unpack_from('>HHHHHH',data,p+6+i*12)
        if ident not in [0,1,2,3,4,5,6,13,14]:continue
        raw=data[p+strings+off:p+strings+off+n]
        try:s=raw.decode('utf-16-be' if platform in [0,3] else 'mac_roman')
        except UnicodeError:continue
        names.setdefault(str(ident),set()).add(s)
    return {k:sorted(v) for k,v in names.items()}

def point(a,r):
    a=math.radians(a);return (64+r*math.cos(a),64+r*math.sin(a))
ray_paths=[]
for i in range(16):
    a=-90+i*22.5
    # Long, distinct gold rays around a large untextured yellow center.
    r=47 if i%2==0 else 42
    pts=[point(a-4.5,25),point(a,r),point(a+4.5,25)]
    ray_paths.append('M '+' L '.join(f'{x:.3f} {y:.3f}' for x,y in pts)+' Z')
rays=' '.join(ray_paths)
contract={
    'asset_id':'pilot_spark_tile','revision':'r002','reference':'output/imagegen/approved/combat.png',
    'viewBox':[0,0,128,128],'center':[64,64],'safe_bounds':[16,16,112,112],
    'ports':{'N':[64,0],'E':[128,64],'S':[64,128],'W':[0,64]},
    'connectivity_r0':{'input':'W','output':'E'},
    'art_contains_ports':False,'rotation_degrees_clockwise':[0,90,180,270],
    'revision_reason':'Owner rejected r001 visual mismatch. Approved Spark is a bright large circular sun with long thin amber rays; dark8-unit silhouette erased that reading at gameplay scale.',
    'r002_outline':{'ray_stroke':1.5,'ray_stroke_color':'#b36c25','center_stroke':2.5,'center_stroke_color':'#d08729'},
    'proposed_r001_outline_units':8,'proposed_r001_internal_units':6,
    'contract_status':'r002 visual-review exception to provisional8/6; ports and128-unit canvas unchanged. Parent owns brief/spec reconciliation after review.',
    'display_sizes':[24,32,48,62,80],
    'gameplay_scale_note':'At62px SVG canvas, essential sun is about46px wide. At80px canvas, sun is about60px wide, matching reference ratio better on137px cells.'
}
svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<title>Spark r002 — long amber rays and bright circular center</title>
<metadata>{json.dumps(contract)}</metadata>
<g id="rays" fill="#f6bb42" stroke="#b36c25" stroke-width="1.5" stroke-linejoin="round"><path d="{rays}"/></g>
<g id="center"><circle cx="64" cy="64" r="20" fill="#ffdc68" stroke="#d08729" stroke-width="2.5"/></g>
<g id="light"><path d="M 46 64 A 18 18 0 0 1 82 64 Z" fill="#ffe681"/></g>
</svg>'''
(HERE/'spark.svg').write_text(svg,encoding='utf8')
(mono := ET.fromstring(svg))
for element in mono.iter():
    for prop in ('fill','stroke'):
        if prop in element.attrib and element.attrib[prop] != 'none':
            element.set(prop,'#142535')
    if element.tag.endswith('}title'):
        element.text='Spark r002 — single dark ink, same sun geometry'
    if element.tag.endswith('}metadata'):
        element.text=json.dumps({**contract,'variant':'single-ink monochrome','visible_ink':'#142535'})
ET.register_namespace('','http://www.w3.org/2000/svg')
(HERE/'spark-monochrome.svg').write_text(ET.tostring(mono,encoding='unicode'),encoding='utf8')
(HERE/'spark-geometry-contract.json').write_text(json.dumps(contract,indent=2)+'\n',encoding='utf8')

# Sharp renders the authoritative SVG; Python composes rendered glyphs and live font evidence.
script=f'''const sharp=require('C:/Users/nguye/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const path=require('path');
(async()=>{{for(const name of ['spark','spark-monochrome'])for(const n of [24,32,48,62,80,128])await sharp(path.join(__dirname,name+'.svg'),{{density:288}}).resize(n,n).png().toFile(path.join(__dirname,name+'-'+n+'.png'));}})();'''
(HERE/'render_spark.cjs').write_text(script,encoding='utf8')

names=metadata_names(FONT)
licence=HERE/'fonts/OFL.NotoSerif.txt'
provenance={
    'font_path':str(FONT),'font_download_url':'https://raw.githubusercontent.com/google/fonts/main/ofl/notoserif/NotoSerif%5Bwdth%2Cwght%5D.ttf',
    'licence_download_url':'https://raw.githubusercontent.com/google/fonts/main/ofl/notoserif/OFL.txt',
    'metadata_download_url':'https://raw.githubusercontent.com/google/fonts/main/ofl/notoserif/METADATA.pb',
    'acquisition_context':'r002 isolated review, after r001 rejection; exact official font, licence and metadata downloaded. No Git commands used.',
    'font_sha256':hashlib.sha256(FONT.read_bytes()).hexdigest(),'font_bytes':FONT.stat().st_size,
    'licence_sha256':hashlib.sha256(licence.read_bytes()).hexdigest(),'license':'SIL Open Font License1.1; actual text retained',
    'sfnt_names':names,'render_variation_axes':{'wght':600,'wdth':100},'pillow_axis_order':['wght','wdth'],
    'production_status':'Review-only acquisition. No runtime asset/import/theme change or production integration.',
    'role_direction':{'title':'Noto Serif SemiBold36','large_action':'Noto Serif SemiBold48','board_label':'Noto Serif SemiBold17','card_label':'Noto Serif SemiBold20','value':'Noto Serif SemiBold30','navigation':'Noto Serif SemiBold21','body':'Noto Serif Regular20 for reference comparison; later inspector usability review required'}
}
(HERE/'font-provenance.json').write_text(json.dumps(provenance,indent=2)+'\n',encoding='utf8')
print(json.dumps({'font_names':names,'sha256':provenance['font_sha256'],'font_bytes':provenance['font_bytes'],'next':'Run render_spark.cjs then compose_specimen.py'},indent=2))
