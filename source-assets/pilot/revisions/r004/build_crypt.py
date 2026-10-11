"""Package the generated clean crypt painting as semantic, non-overlapping layers.

This is an editable illustration plate, not a parallax environment. No hidden
architecture is invented underneath its separated regions. Recomposition is exact.
"""
from pathlib import Path
from io import BytesIO
import hashlib, json, zipfile
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageDraw, ImageCms

P=Path(__file__).resolve().parent
ROOT=P.parents[3]
OUT=ROOT/'output/art/rc-011/r004'
SRC=P/'crypt'
SRC.mkdir(exist_ok=True)
(SRC/'layers').mkdir(exist_ok=True)
ICC=ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
raw=P/'raw/crypt-background.png'
im=Image.open(raw).convert('RGBA')
assert im.size==(841,1870), im.size
w,h=im.size
regions=[
 ('Central recessed stone',[(0,0),(841,0),(841,1870),(0,1870)]),
 ('Rear arches statues banners and brazier',[(0,0),(841,0),(841,340),(797,372),(695,352),(616,374),(486,370),(339,381),(243,364),(124,379),(0,348)]),
 ('Arena cobblestone floor',[(0,348),(124,379),(243,364),(339,381),(486,370),(616,374),(695,352),(797,372),(841,340),(841,520),(713,504),(608,532),(440,551),(220,532),(117,511),(0,505)]),
 ('Left rocky surround',[(0,348),(59,345),(125,402),(146,520),(102,666),(89,905),(70,1060),(96,1248),(88,1389),(151,1547),(178,1693),(238,1803),(187,1870),(0,1870)]),
 ('Right rocky surround',[(841,340),(794,348),(737,427),(699,532),(748,719),(766,915),(770,1082),(751,1217),(728,1321),(735,1413),(688,1570),(655,1703),(612,1794),(653,1870),(841,1870)]),
 ('Left foreground candle clusters',[(0,1111),(51,1111),(83,1195),(111,1273),(68,1318),(0,1280),(0,1590),(49,1590),(90,1650),(139,1703),(162,1780),(128,1827),(0,1803)]),
 ('Right foreground candle clusters',[(841,1120),(794,1120),(767,1191),(747,1256),(791,1297),(841,1280),(841,1590),(783,1590),(765,1652),(717,1700),(696,1780),(732,1827),(841,1803)]),
]
# Separate disjoint candle clusters with an explicit union, avoiding the connecting
# polygons crossing the rail. Later regions own pixels on shared boundaries.
labels=np.zeros((h,w),dtype=np.uint8)
for idx,(name,pts) in enumerate(regions[1:],1):
    mask=Image.new('L',(w,h));d=ImageDraw.Draw(mask)
    if idx>=5:
        d.polygon(pts[:8],fill=255)
        d.polygon(pts[8:],fill=255)
    else:d.polygon(pts,fill=255)
    labels[np.asarray(mask)>0]=idx
arr=np.array(im)
layers=[]
for idx,(name,pts) in enumerate(regions):
    a=np.zeros_like(arr);a[labels==idx]=arr[labels==idx]
    layer=Image.fromarray(a)
    slug=name.lower().replace(' ','-')
    path=SRC/'layers'/f'{idx:02d}-{slug}.png'
    layer.save(path,icc_profile=ICC)
    layers.append((name,path,layer))
merged=Image.new('RGBA',im.size)
for _,_,layer in layers:merged=Image.alpha_composite(merged,layer)
assert np.array_equal(np.asarray(im),np.asarray(merged))
merged.save(P/'exports/crypt-background.png',icc_profile=ICC)
merged.save(SRC/'merged.png',icc_profile=ICC)
def png_bytes(image):
    b=BytesIO();image.save(b,format='PNG',icc_profile=ICC);return b.getvalue()
root=ET.Element('image',{'w':str(w),'h':str(h),'name':'RC-011 r004 complete Ashen Crypt','version':'0.0.3'})
stack=ET.SubElement(root,'stack')
with zipfile.ZipFile(SRC/'crypt.ora','w') as z:
    z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
    for i,(name,path,layer) in reversed(list(enumerate(layers))):
        dest=f'data/layer{i:02d}.png'
        ET.SubElement(stack,'layer',{'name':name,'src':dest,'x':'0','y':'0','opacity':'1.0','visibility':'visible','composite-op':'svg:src-over'})
        z.writestr(dest,path.read_bytes(),compress_type=zipfile.ZIP_DEFLATED)
    z.writestr('stack.xml',ET.tostring(root,encoding='utf-8',xml_declaration=True))
    z.writestr('mergedimage.png',png_bytes(merged))
    thumb=merged.copy();thumb.thumbnail((256,256));z.writestr('Thumbnails/thumbnail.png',png_bytes(thumb))
paths=''.join(f'<polygon id="region-{i}" data-name="{name}" points="'+ ' '.join(f'{x},{y}' for x,y in pts)+'" fill="none" stroke="#ffcf62" stroke-width="2"/>' for i,(name,pts) in enumerate(regions[1:],1))
(SRC/'separation-regions.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 841 1870">{paths}</svg>',encoding='utf-8')
meta={
 'revision':'r004','size':[w,h],'color_space':'sRGB','alpha':'opaque composite; straight-alpha semantic parts',
 'generation':{'tool':'built-in image_gen','model':None,'seed':None,'prompt':'../raw/crypt-background.prompt.txt','raw':'../raw/crypt-background.png','raw_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'reference':'output/imagegen/approved/combat-final.png','reference_sha256':hashlib.sha256((ROOT/'output/imagegen/approved/combat-final.png').read_bytes()).hexdigest(),'original_tool_output':'C:/Users/nguye/.codex/generated_images/01a125b7-21db-7683-ac68-ba49d0b1e8d3/exec-d4d285d2-a68c-43d5-8a59-c15d16f1c99c.png'},
 'layers':[{'name':name,'path':str(path.relative_to(SRC)),'bbox':layer.getbbox()} for name,path,layer in layers],
 'pixel_exact_recomposition':True,'production_reference_crop':False,
 'editability':'Seven disjoint semantic paint layers, retained generation, explicit masks and repeatable source. Color correction, repaint and replacement are supported. Hidden areas are not reconstructed; arbitrary parallax or relocation needs paint extension.',
 'memory_rgba8_mib':round(w*h*4/1048576,3),'parts_rgba8_mib':round(w*h*4*len(layers)/1048576,3),
 'scope':'Isolated asset review; not imported into gameplay or device tested.'
}
(SRC/'metadata.json').write_text(json.dumps(meta,indent=2)+'\n',encoding='utf-8')
# Contact sheet makes every actual layer inspectable, including transparent pixels.
sheet=Image.new('RGB',(280*4,660*2),'#111725')
from PIL import ImageFont
font=ImageFont.truetype(str(P.parent/'r002/type-geometry/fonts/NotoSerif-Variable.ttf'),15)
for i,(name,path,layer) in enumerate(layers):
    x=(i%4)*280;y=(i//4)*660
    sample=layer.copy();sample.thumbnail((270,602));sheet.paste(sample,(x+5,y+45),sample)
    d=ImageDraw.Draw(sheet);words=name.split();lines=[' '.join(words[:3]),' '.join(words[3:])]
    for k,t in enumerate(lines):d.text((x+6,y+5+k*18),t,fill='#ffedb7',font=font)
sheet.save(OUT/'crypt-layers.png',icc_profile=ICC)
print(json.dumps({'layers':len(layers),'exact_recomposition':True,'size':[w,h]}))
