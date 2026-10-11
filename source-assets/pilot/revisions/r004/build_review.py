"""RC-011 r004 complete editable gameplay review. No runtime integration.

Original UI geometry and live-style text over original generated environment and
painted materials. The approved reference is not linked or sampled in this source.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps,ImageFilter,ImageChops,ImageCms
from html import escape
from io import BytesIO
import importlib.util,json,math,random,base64,xml.etree.ElementTree as ET,subprocess,zipfile,hashlib

P=Path(__file__).resolve().parent
ROOT=P.parents[3]
UI=P/'ui';UI.mkdir(exist_ok=True)
OUT=ROOT/'output/art/rc-011/r004';OUT.mkdir(parents=True,exist_ok=True)
FONT=P.parent/'r002/type-geometry/fonts/NotoSerif-Variable.ttf'
NODE='C:/Users/nguye/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
CREAM='#fff0bf';GOLD='#d2a05b';TEAL='#72f7eb';AMBER='#ffd86a';NAVY='#101b2d'
ICC=ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()

def rect(x,y,w,h,fill,stroke='none',sw=1,rx=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def path(d,fill='none',stroke='none',sw=1,extra=''):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round" {extra}/>'
def poly(points,fill,stroke='none',sw=1):
    pts=' '.join(f'{x:.3f},{y:.3f}' for x,y in points) if not isinstance(points,str) else points
    return f'<polygon points="{pts}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"/>'
def circle(x,y,r,fill,stroke='none',sw=1):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def group(s,id=None,transform=None):
    return '<g'+(f' id="{id}"' if id else '')+(f' transform="{transform}"' if transform else '')+'>'+s+'</g>'
def img(href,x,y,w,h,extra=''):
    return f'<image xlink:href="{href}" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="none" {extra}/>'
def text(x,y,s,size=20,fill=CREAM,anchor='start',weight=600,stroke=2):
    return f'<text x="{x}" y="{y}" font-family="Noto Serif" font-size="{size}" font-weight="{weight}" fill="{fill}" stroke="#080d15" stroke-width="{stroke}" paint-order="stroke fill" stroke-linejoin="round" text-anchor="{anchor}">{escape(str(s))}</text>'
def document(w,h,s,title):
    return f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><title>{escape(title)}</title><metadata>RC-011 r004 original complete editable gameplay construction; candidate, no owner acceptance or runtime claim. Undirected ports; visual example values remain live-style text.</metadata><defs><filter id="amberGlow" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="5"/></filter><filter id="tealGlow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter></defs>'+s+'</svg>'

def prepare_materials():
    folder=UI/'materials';folder.mkdir(exist_ok=True)
    for name in ['navy','turquoise','amber']:
        im=Image.open(P.parent/'r002/ui/materials'/f'{name}.png').convert('RGB')
        im.save(folder/f'{name}.png')
    navy=Image.open(folder/'navy.png')
    gray=ImageOps.autocontrast(ImageOps.grayscale(navy))
    for name,lo,hi in [('green','#092715','#286e2c'),('violet','#201035','#5d267b'),('parchment','#97713c','#e2c181')]:
        im=ImageOps.colorize(gray,lo,hi);im.save(folder/f'{name}.png')
    # No old direction metadata is copied into the revised glyph.
    glyph=(P.parent/'r002/type-geometry/spark.svg').read_text(encoding='utf-8')
    import re
    glyph=re.sub(r'<metadata>.*?</metadata>','<metadata>r004 reusable amber Spark symbol; no baked connection or direction semantics; viewBox128; four exact edge ports are separate.</metadata>',glyph,flags=re.S)
    (UI/'spark.svg').write_text(glyph,encoding='utf-8')
    prepare_painted_frame()
    prepare_painted_buttons()

def prepare_painted_buttons():
    for rawname,name,points in [
        ('navy-panel','navy-panel',[(52,40),(972,40),(994,88),(994,180),(972,216),(52,216),(28,181),(28,86)]),
        ('cast-button','cast-button',[(101,30),(923,30),(974,128),(923,226),(101,226),(49,128)])]:
        raw=Image.open(P/'raw'/f'{rawname}.png').convert('RGBA');a=raw.getchannel('A').point(lambda v:255 if v>170 else 0);crop=a.getbbox()
        im=raw.crop(crop).resize((1024,256),Image.Resampling.LANCZOS)
        mask=Image.new('L',im.size);ImageDraw.Draw(mask).polygon(points,fill=255)
        face=im.copy();face.putalpha(ImageChops.multiply(im.getchannel('A'),mask))
        rim=im.copy();rim.putalpha(ImageChops.multiply(im.getchannel('A'),ImageOps.invert(mask)))
        for suffix,part in [('base',im),('face',face),('rim',rim)]:part.save(UI/f'{name}-{suffix}.png',icc_profile=ICC)
        make_ora(UI/f'{name}.ora',(1024,256),[('Generated painted face with transparent complement',face,True),('Generated painted gold and dark rim',rim,True)])
        (UI/f'{name}-mask.svg').write_text(document(1024,256,poly(points,'white'),'Editable paint separation mask; rim uses complement'),encoding='utf-8')
        (UI/f'{name}-metadata.json').write_text(json.dumps({'raw':f'../raw/{rawname}.png','prompt':f'../raw/{rawname}.prompt.txt','crop_bbox':list(crop),'master':[1024,256],'source_method':'Genuine complementary face/rim separation of generated artwork; pixels not duplicated. Detailed strokes are flattened paint.','raw_sha256':hashlib.sha256((P/'raw'/f'{rawname}.png').read_bytes()).hexdigest(),'status':'r004 candidate; no approval inferred'},indent=2),encoding='utf-8')
    # Use complete generated material under general UI, preserving depth variation.
    navy=Image.open(UI/'navy-panel-face.png').crop((85,46,940,211)).convert('RGB');navy.save(UI/'materials/navy.png',icc_profile=ICC)

def painted_component(x,y,w,h,name='navy-panel',border=7):
    raw=Image.open(UI/f'{name}-base.png').convert('RGBA')
    file=f'{name}-{round(w)}x{round(h)}-{border}.png';dest=UI/file
    if name=='cast-button':
        # Fixed endplates preserve the generated hexagonal construction at live height.
        margins=(112,36,112,36);capx=round(h*.40);capy=round(h*.10)
    else:margins=(76,40,76,40);capx=max(10,round(border*2));capy=max(5,round(border*1.1))
    out=Image.new('RGBA',(round(w),round(h)));l,t,r,b=margins
    xs=[0,l,1024-r,1024];ys=[0,t,256-b,256];xd=[0,capx,round(w)-capx,round(w)];yd=[0,capy,round(h)-capy,round(h)]
    for j in range(3):
        for i in range(3):
            patch=raw.crop((xs[i],ys[j],xs[i+1],ys[j+1])).resize((xd[i+1]-xd[i],yd[j+1]-yd[j]),Image.Resampling.LANCZOS);out.paste(patch,(xd[i],yd[j]))
    out.save(dest,icc_profile=ICC)
    return img('ui/'+file,x,y,w,h)

def prepare_painted_frame():
    raw=Image.open(P/'raw/empty-tile.png').convert('RGBA')
    a=raw.getchannel('A').point(lambda v:255 if v>170 else 0)
    crop=a.getbbox();im=raw.crop(crop).resize((512,512),Image.Resampling.LANCZOS)
    # Genuine complementary masks, traced around the inward edge of the frame.
    cut=Image.new('L',(512,512));d=ImageDraw.Draw(cut)
    pts=[(75,39),(435,39),(475,81),(475,427),(434,472),(77,472),(36,429),(36,80)]
    d.polygon(pts,fill=255)
    face=im.copy();face.putalpha(ImageChops.multiply(im.getchannel('A'),cut))
    frame=im.copy();frame.putalpha(ImageChops.multiply(im.getchannel('A'),ImageOps.invert(cut)))
    im.save(UI/'painted-tile-source.png',icc_profile=ICC);frame.save(UI/'painted-frame.png',icc_profile=ICC)
    face.save(UI/'painted-face.png',icc_profile=ICC)
    gray=ImageOps.grayscale(im);low,high=gray.crop((75,75,436,436)).getextrema()
    tone=gray.point(lambda v:max(0,min(255,round((v-low)*255/max(1,high-low)))))
    for name,lo,hi in [('navy','#142237','#3e5271'),('amber','#211309','#744611'),('turquoise','#05282b','#0c6255'),('green','#0a260f','#2e6826'),('violet','#1a1031','#572675')]:
        tint=ImageOps.colorize(tone,lo,hi).convert('RGBA');tint.putalpha(face.getchannel('A'))
        tint.save(UI/f'painted-face-{name}.png',icc_profile=ICC)
        merged=tint.copy();merged.alpha_composite(frame);merged.resize((256,256),Image.Resampling.LANCZOS).save(UI/f'tile-{name}.png',icc_profile=ICC)
        # Painted face center reused as a quiet textured material, from generated art only.
        tint.crop((75,75,436,436)).convert('RGB').save(UI/'materials'/f'{name}.png',icc_profile=ICC)
        if name=='navy':tint.crop((75,75,436,436)).convert('RGB').save(UI/'materials/board-stone.png',icc_profile=ICC)
    for name,lo,hi in [('green','#082812','#a9ef72'),('violet','#21102c','#d18bf7')]:
        colored=ImageOps.colorize(ImageOps.grayscale(frame),lo,hi).convert('RGBA');colored.putalpha(frame.getchannel('A'));colored.save(UI/f'painted-frame-{name}.png',icc_profile=ICC)
    layers=[('Original painted stone face',face,False)]
    for name in ['amber','turquoise','green','violet']:
        layers.append((f'{name} material variant',Image.open(UI/f'painted-face-{name}.png').convert('RGBA'),name=='amber'))
    layers.append(('Painted sculpted gold and dark rim',frame,True))
    make_ora(UI/'painted_tile.ora',(512,512),layers)
    (UI/'painted-frame-mask.svg').write_text(document(512,512,poly(pts,'white'),'Editable inner-face separation mask; gold rim uses complement'),encoding='utf-8')
    meta={'raw':'../raw/empty-tile.png','prompt':'../raw/empty-tile.prompt.txt','crop_alpha_threshold':170,'crop_bbox':list(crop),'master':[512,512],'export':[256,256],'separation':'Complementary interior-face and gold/dark-rim masks; alternate material recolors hidden. No duplicated full composite layers. Underlying strokes remain flattened generated paint.','raw_sha256':hashlib.sha256((P/'raw/empty-tile.png').read_bytes()).hexdigest(),'reference_pixels_used':False,'nine_slice_proposal':'Painted bevel requires24exportpixel caps for this candidate;16px draft is insufficient. Responsive vector composition used where dimensions vary. Owner acceptance not inferred.'}
    (UI/'painted-frame-metadata.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')

def make_ora(dest,size,layers):
    tree=ET.Element('image',{'w':str(size[0]),'h':str(size[1]),'name':'r004 UI painted construction','version':'0.0.3'});stack=ET.SubElement(tree,'stack')
    merge=Image.new('RGBA',size)
    for name,im,vis in layers:
        if vis:merge.alpha_composite(im)
    with zipfile.ZipFile(dest,'w') as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for i,(name,im,vis) in reversed(list(enumerate(layers))):
            src=f'data/layer{i:02}.png';b=BytesIO();im.save(b,format='PNG',icc_profile=ICC);z.writestr(src,b.getvalue())
            ET.SubElement(stack,'layer',{'name':name,'src':src,'x':'0','y':'0','opacity':'1','visibility':'visible' if vis else 'hidden','composite-op':'svg:src-over'})
        z.writestr('stack.xml',ET.tostring(tree));b=BytesIO();merge.save(b,format='PNG',icc_profile=ICC);z.writestr('mergedimage.png',b.getvalue())

def painted_border(x,y,w,h,cap=14,variant='gold'):
    name=f'frame-{variant}-{round(w)}x{round(h)}-{round(cap)}.png';dest=UI/name
    # Whole painted rim stretches only on its straight mid-sections.
    raw=Image.open(UI/('painted-frame.png' if variant=='gold' else f'painted-frame-{variant}.png')).convert('RGBA');out=Image.new('RGBA',(round(w),round(h)));a=48
    xs=[0,a,512-a,512];ys=xs;xd=[0,cap,round(w)-cap,round(w)];yd=[0,cap,round(h)-cap,round(h)]
    for j in range(3):
        for i in range(3):
            if i==j==1:continue
            patch=raw.crop((xs[i],ys[j],xs[i+1],ys[j+1])).resize((xd[i+1]-xd[i],yd[j+1]-yd[j]),Image.Resampling.LANCZOS)
            out.paste(patch,(xd[i],yd[j]))
    out.save(dest,icc_profile=ICC)
    return img('ui/'+name,x,y,w,h)

_panel_id=0
def panel(x,y,w,h,material='navy',border=6,shape='box',trim='#b57a37',detail=True):
    """Jagged sculpted gold/dark frame, painted inset, vector bevels at actual size."""
    global _panel_id
    if shape=='cast' and material=='turquoise':return painted_component(x,y,w,h,'cast-button',border)
    if material=='navy' and detail and h>w*.45:
        # Tall boards use the original square stone and square rim, never a
        # vertically stretched horizontal-panel source.
        _panel_id+=1;pid=f'tall{_panel_id}'
        s=f'<defs><clipPath id="{pid}">{rect(x+3,y+3,w-6,h-6,"white",rx=12)}</clipPath></defs>'
        s+=img('ui/materials/board-stone.png',x,y,w,h,f'clip-path="url(#{pid})"')+painted_border(x,y,w,h,max(12,round(border*2)))
        return s
    if material=='navy' and detail:return painted_component(x,y,w,h,'navy-panel',border)
    _panel_id+=1;pid=f'panel{_panel_id}';b=border
    c=min(17,h*.19,w*.13)
    if shape=='cast':
        c=h*.32;outer=[(x+c,y),(x+w-c,y),(x+w,y+h/2),(x+w-c,y+h),(x+c,y+h),(x,y+h/2)]
        inner=[(x+c+b,y+b),(x+w-c-b,y+b),(x+w-2*b,y+h/2),(x+w-c-b,y+h-b),(x+c+b,y+h-b),(x+2*b,y+h/2)]
    else:
        outer=[(x+c,y),(x+w-c,y),(x+w,y+c),(x+w,y+h-c),(x+w-c,y+h),(x+c,y+h),(x,y+h-c),(x,y+c)]
        inner=[(x+c+b*.2,y+b),(x+w-c-b*.2,y+b),(x+w-b,y+c+b*.2),(x+w-b,y+h-c-b*.2),(x+w-c-b*.2,y+h-b),(x+c+b*.2,y+h-b),(x+b,y+h-c-b*.2),(x+b,y+c+b*.2)]
    s=poly(outer,'#181820','#080c14',4)
    s+=f'<defs><clipPath id="{pid}">{poly(inner,"white")}</clipPath></defs>'
    s+=img('ui/materials/'+material+'.png',x,y,w,h,f'clip-path="url(#{pid})"')
    col=[trim,'#cd9a55','#855525','#684623','#b78040','#dfb46e','#be8d4c','#e6bf76']
    for i in range(len(outer)):
        j=(i+1)%len(outer);s+=poly([outer[i],outer[j],inner[j],inner[i]],col[i%8],'#49321f',.7)
    top='M'+' L'.join(f'{a},{b1}' for a,b1 in outer[:3])
    s+=path(top,'none','#f1c87b',1.8)
    s+=poly(inner,'none','#131522',2.4)
    rim='#26d2c4' if material=='turquoise' else '#8875a5' if material=='violet' else '#80b258' if material=='green' else '#56708b' if material=='navy' else '#c68c34'
    inset=[(xx+(b*.15 if xx<x+w/2 else -b*.15),yy+(b*.15 if yy<y+h/2 else -b*.15)) for xx,yy in inner]
    s+=poly(inset,'none',rim,1.4)
    if detail and w>220:
        # Irregular hand-hewn gold edge chips: subordinate to the live label.
        for k,fx in enumerate([.16,.38,.61,.79]):
            xx=x+w*fx
            s+=poly([(xx-8,y+1),(xx,y+2+(k%2)),(xx+12,y+1),(xx+7,y+b*.6),(xx-7,y+b*.52)],['#d4a55f','#ab7537','#e9c27a','#c69552'][k])
            s+=path(f'M{xx-7},{y+h-1} l9,-2 11,1','none','#50381f',1)
    if shape=='box' and detail and material!='parchment':
        s+=painted_border(x,y,w,h,max(8,round(border*1.7)),material if material in ['green','violet'] else 'gold')
    return group(s)

def icon(name,x,y,size,color=CREAM):
    """Original editable 100-unit pictograms with broad outlined facets."""
    o='#101522';s=''
    if name=='heart':
        s=path('M50 91 C38 80 9 58 8 33 C5 9 33 3 50 25 C69 2 97 12 92 37 C88 60 63 82 50 91','#e84145',o,5)+path('M50 82 C60 65 72 43 67 20 C91 9 96 31 86 50 Z','#b72a35')+path('M18 33 C15 19 30 13 40 25','none','#ff8176',8)
    elif name=='crystal':
        s=poly('50,2 81,26 79,73 50,98 20,74 18,26','#038cde',o,5)+poly('50,3 50,47 20,26','#55e7ff')+poly('50,47 81,26 78,73 50,96','#0073c6')+poly('50,3 81,26 50,47','#14b9fa')+path('M50 47V96 M20 26L50 47L80 26','none','#88f4ff',2)
    elif name=='shield':
        s=path('M50 5 Q74 21 91 19 L87 58 Q77 82 50 96 Q22 81 14 58 L10 19 Q34 22 50 5','#2e9c4c',o,5)+path('M50 12V87 Q73 75 81 53 L83 27 Q67 28 50 12','#54d06b')+path('M20 27 Q38 29 50 15V55H22Z','#9df691')+path('M50 13V87 M20 54H81','none','#b2ffab',3)
    elif name in ['book','guide']:
        s=path('M50 20 Q27 5 5 18 L4 83 Q29 73 50 91 Q75 74 96 82 L95 18 Q71 6 50 20', '#a66be5' if name=='book' else '#dfba76',o,5)
        s+=path('M49 27 Q32 16 13 23V74 Q32 70 49 84 M53 27 Q70 16 88 23V74 Q71 70 53 84','none','#e6c9ff' if name=='book' else '#fff0b2',5)
        s+=path('M50 21V87 M20 35Q33 32 43 39 M20 47Q33 43 43 50 M61 38Q73 32 82 35 M61 50Q73 44 82 47','none','#dcc0f9' if name=='book' else '#8b6637',3)
        if name=='guide':s+=path('M60 39C60 20 85 26 78 40L69 50V57 M69 67V70','none','#271d1e',6)
    elif name=='sword':
        s=poly('76,3 91,0 87,17 41,66 30,55','#ff6d68',o,4)+poly('76,3 79,15 35,62 30,55','#ffb2a0')+path('M20 48L47 72 M31 60L12 84 M6 83L16 93','none','#e54744',9)
    elif name=='remove':
        s=poly('16,64 59,13 88,37 47,88','#f4cf82',o,6)+poly('16,64 32,45 61,69 47,88','#284057',o,4)+path('M61 18L81 35','none','#ffeaba',4)
    elif name=='rotate':
        s=path('M75 22 A34 34 0 1 0 84 64','none',color,12)+poly('74,6 95,33 65,37',color,o,3)
    elif name=='menu':
        for yy in [20,43,66]:s+=rect(14,yy,72,11,color,o,3)
    elif name=='pause':
        s=rect(27,14,16,72,color,o,3)+rect(60,14,16,72,color,o,3)
    elif name=='sound':
        s=poly('9,38 30,38 50,19 50,81 30,64 9,64',color,o,4)+path('M63 31Q87 50 63 70 M74 19Q110 50 74 83','none',color,6)
    elif name=='map':
        s=poly('5,20 33,9 66,22 95,7 95,78 64,92 33,79 5,92','#e7c07c',o,4)+path('M33 10V78 M65 23V89','none','#94703d',3)
        s+=path('M20 62Q21 28 44 40T78 51','none','#2b2823',5, 'stroke-dasharray="5 5"')+circle(20,62,5,'#252522')+poly('77,36 83,44 77,53 71,44','#252522')
    elif name=='skull':
        s=path('M15 40C12 2 87 1 87 41L76 59V83H26V60Z','#8790a1',o,4)+circle(34,39,12,'#202b40')+circle(67,39,12,'#202b40')+poly('50,48 43,62 57,62','#202b40')+path('M37 72V88 M50 72V88 M63 72V88','none','#202b40',5)
    elif name=='deck':
        s=circle(50,50,35,'none','#748ca5',3)+path('M50 9V91 M9 50H91 M21 22L80 80 M20 80L80 20','none','#748ca5',2)+poly('50,16 61,42 83,50 61,60 50,86 40,59 16,50 40,40','none','#9aaac0',2)
    elif name=='check':s=path('M13 49L39 74L90 16','none',color,13)
    elif name=='spark':return img('ui/spark.svg',x,y,size,size)
    elif name=='split':s=path('M13 57H49L54 14 M49 57L78 87','none',color,12)
    elif name=='join':s=path('M12 71H88 M50 71V18','none',color,12)
    elif name=='straight':s=path('M8 50H92','none',color,12)
    elif name=='corner':s=path('M12 27H73V86','none',color,12)
    elif name=='infinity':s=path('M50 50C26 17 4 25 4 50C4 76 28 83 50 50C72 17 96 25 96 50C96 76 71 83 50 50','none',color,8)
    return group(s,transform=f'translate({x} {y}) scale({size/100})')

def energy_badge(x,y,value,size=38):
    return icon('crystal',x-size/2,y-size/2,size)+text(x,y+size*.24,value,size*.60,'#f0fbff','middle',700,3)
def beam(d,color=AMBER,width=8):
    return path(d,'none','#ed9d25',width+5,'opacity=".65" filter="url(#amberGlow)"')+path(d,'none',color,width)+path(d,'none','#fff3a2',max(1,width*.24))

def tile(x,y,w,h,kind='empty',label='',value=None,cost=None,temp=False):
    material='amber' if kind=='spark' else 'turquoise' if kind in ['begin','end','split','join'] else 'navy'
    s=img(f'ui/tile-{material}.png',x,y,w,h)
    cx=x+w/2;cy=y+h/2
    if kind=='spark':s+=icon('spark',cx-56,cy-53,112)
    if kind in ['begin','end']:
        s+=circle(cx,cy,44,'#07595c')
        if kind=='end':
            s+=path(f'M{cx-24} {cy+37} A44 44 0 1 1 {cx+24} {cy+37}','none','#31dce1',6)
        else:s+=circle(cx,cy,44,'none','#31dce1',6)
        s+=circle(cx,cy,34,'#03434b','#258b94',3)
        s+=poly([(cx,cy-16),(cx+16,cy),(cx,cy+16),(cx-16,cy)],'#80fff0','#24bac1',2)
        if kind=='begin':s+=poly([(cx-15,cy-6),(cx-4,cy+6),(cx+17,cy-14),(cx+21,cy-9),(cx-4,cy+15),(cx-20,cy)],'#73fff1')
    if kind in ['split','join']:s+=icon(kind,cx-32,cy-30,64,TEAL if kind=='split' else '#81fbbb')
    if label:s+=text(cx if kind in ['begin','end'] else x+18,y+h-17 if kind=='begin' else y+28,label,21 if kind in ['begin','end'] else 18,CREAM,'middle' if kind in ['begin','end'] else 'start',700)
    if value is not None:s+=text(x+28 if temp else cx,y+h-18,value,29,CREAM,'middle',600,3)
    if cost is not None:s+=energy_badge(x+w-30,y+27,cost,39)
    if temp:
        s+=poly([(x+w-74,y+h-33),(x+w-17,y+h-33),(x+w-10,y+h-23),(x+w-17,y+h-10),(x+w-74,y+h-10),(x+w-82,y+h-22)],'#d7a04d','#493015',2)
        s+=text(x+w-46,y+h-15,'TEMP',15,'#191813','middle',700,0)
    return s

def official_board(x=93,y=644,cw=164,ch=146):
    s=''
    for row in range(4):
        for col in range(4):
            kind={(0,0):'begin',(0,1):'spark',(0,2):'split',(2,2):'join',(3,2):'end'}.get((row,col),'empty')
            s+=tile(x+col*cw,y+row*ch,cw-4,ch-4,kind)
    # Undirected edges drawn above faces, below symbol centers. No arrowhead geometry.
    c=lambda col,row:(x+col*cw+(cw-4)/2,y+row*ch+(ch-4)/2)
    a,b,c2,d=c(0,0),c(1,0),c(2,0),c(3,0);join=c(2,2);end=c(2,3)
    s+=beam(f'M{a[0]+42},{a[1]}H{b[0]-47}')+beam(f'M{b[0]+47},{b[1]}H{c2[0]-43}')
    s+=beam(f'M{c2[0]+43},{c2[1]}H{d[0]-15}Q{d[0]},{d[1]} {d[0]},{d[1]+16}V{join[1]-16}Q{d[0]},{join[1]} {d[0]-16},{join[1]}H{join[0]+43}')
    s+=beam(f'M{c2[0]},{c2[1]+42}V{y+2*ch+5}')+beam(f'M{join[0]},{join[1]+38}V{end[1]-42}')
    for cx in [c2[0],d[0]]:
        yy=y+ch*1.47;s+=circle(cx,yy,20,'#442c11')+text(cx,yy+10,'6',31,CREAM,'middle',600,3)
    # Live labels/value remain separate from art and uninterrupted by geometry.
    s+=text(a[0],y+ch-20,'BEGIN',22,CREAM,'middle',700)
    s+=text(x+cw+18,y+28,'SPARK',18,CREAM,weight=700)+energy_badge(x+2*cw-31,y+27,'0',39)
    s+=text(b[0]-11,y+ch-18,'6',30,CREAM,'middle',600,3)
    s+=poly([(x+cw+83,y+ch-34),(x+2*cw-14,y+ch-34),(x+2*cw-7,y+ch-23),(x+2*cw-15,y+ch-9),(x+cw+83,y+ch-9),(x+cw+74,y+ch-21)],'#d5a452','#432915',2)
    s+=text(x+cw+118,y+ch-15,'TEMP',15,'#21160c','middle',700,0)
    s+=text(x+2*cw+18,y+28,'SPLIT',18,CREAM,weight=700)+energy_badge(x+3*cw-29,y+27,'1',39)
    s+=text(join[0],y+2*ch+28,'JOIN',19,CREAM,'middle',700)
    s+=text(end[0],y+3*ch+111,'END',21,CREAM,'middle',700)+text(end[0],y+4*ch-17,'12',28,CREAM,'middle',600,3)
    return group(s,'undirected_circuit_visual_example')

def deck(x,y,label,count,discard=False):
    s=''
    for i in range(4,-1,-1):s+=panel(x+i*4,y-i*4,73,112,'navy',3,trim='#687486',detail=False)
    s+=icon('skull' if discard else 'deck',x+14,y+25,47)
    s+=rect(x+20,y+91,39,29,'#0b131e','#a2824e',2,5)+text(x+39,y+114,count,24,CREAM,'middle',600)
    s+=text(x+38,y+136,label,16,CREAM,'middle',700)
    return group(s)
def card(x,y,w,h,name,cost,kind,role,description):
    mat={'spark':'amber','shield':'green','book':'violet'}[kind]
    s=panel(x,y,w,h,mat,7,trim={'spark':'#c48b31','shield':'#73a94c','book':'#996bd0'}[kind])
    s+=energy_badge(x+23,y+22,cost,39)+icon(kind,x+w/2-37,y+13,74)
    s+=text(x+w/2,y+89,name,27,CREAM,'middle',700,3)
    s+=path(f'M{x+24} {y+99}H{x+w-24}','none','#a67e3d' if kind=='spark' else '#6f9749' if kind=='shield' else '#b080d3',2)
    s+=text(x+w/2,y+117,role,15,{'spark':'#f7d16a','shield':'#b4de7c','book':'#d2acf4'}[kind],'middle',600,1)
    s+=path(f'M{x+24} {y+124}H{x+w-24}','none','#806334',1)
    s+=text(x+w/2,y+149,description,19,CREAM,'middle',600,2)
    return group(s)

def main():
    s=img('exports/crypt-background.png',0,0,841,1870)
    s+=text(59,43,'Rune Cast',47,'#efb252',weight=700,stroke=4)+text(696,33,'Floor 3 · Ashen Crypt',23,CREAM,'end',500,2)
    s+=path('M49 54L103 50L318 49L512 48L696 50','none','#997042',4)
    s+=panel(723,7,77,58,'navy',6,detail=False)+icon('pause',738,16,44)
    s+=icon('sword',386,111,42)+text(443,143,'8',35,'#fffbea','middle',600,4)
    # Shared character origin retained. Display scale matches official full-body silhouette.
    s+=img('../r002/exports/shadeling.png',254,92,384,384)
    s+=text(421,428,'BOSS',16,'#f1c835','middle',700,2)+text(421,451,'Shadeling',22,CREAM,'middle',700,3)
    s+=poly('321,457 517,457 528,472 516,487 322,487 310,472','#c82830','#1b1720',3)
    s+=path('M322 460H515','none','#ff6c4e',3)+text(420,482,'32/32',26,'#fff9e0','middle',700,3)
    # Three continuous slim panels, with live values.
    for xx,ww in [(29,251),(280,282),(562,247)]:s+=panel(xx,512,ww,63,'navy',6)
    s+=icon('heart',61,522,48)+text(120,557,'24/30',33,'#fff8e2',weight=600,stroke=3)
    s+=icon('crystal',377,524,31)+text(423,555,'3/3',31,'#d9ffff',weight=600,stroke=3)
    s+=panel(653,523,128,41,'parchment',3,detail=False)+text(717,554,'Turn 2',27,'#17191b','middle',700,0)
    s+=panel(23,576,793,683,'navy',10)
    ribbon='137,583 182,583 191,588 204,583 661,583 669,588 709,583 704,605 700,613 704,628 677,626 672,631 187,631 181,626 154,633 143,629 134,633 139,613 134,605 132,591'
    s+=f'<defs><clipPath id="ribbon">{poly(ribbon,"white")}</clipPath></defs>'+img('ui/materials/turquoise.png',133,582,577,54,'clip-path="url(#ribbon)"')+poly(ribbon,'none','#0b181b',4)
    s+=path('M149 586L688 585','none','#367960',2)+icon('check',227,587,53,'#6bfcaa')+text(452,619,'CIRCUIT COMPLETE',31,'#64f1a4','middle',700,4)
    s+=official_board()
    # Wiring and the two accepted editing actions only.
    s+=panel(25,1250,789,123,'navy',8)
    s+=panel(42,1284,105,51,'parchment',3,detail=False)+text(95,1319,'WIRING',22,'#211a14','middle',700,0)
    for i,(label,shape,count,col) in enumerate([('Straight','straight','∞',AMBER),('Corner','corner','∞',AMBER),('Split','join','0/1',TEAL),('Join','join','0/1',AMBER)]):
        xx=160+i*107;s+=panel(xx,1261,95,96,'navy',3,trim='#6b707b',detail=False)
        s+=text(xx+47,1278,label,17,CREAM,'middle',600)+icon(shape,xx+22,1285,53,col)
        s+=path(f'M{xx+10} 1331H{xx+85}','none','#6d6251',1)
        s+=icon('infinity',xx+32,1335,29,'#f7f2df') if i<2 else text(xx+47,1352,count,26,'#f95657','middle',500,2)
    for xx,label,shape in [(609,'REMOVE','remove'),(713,'ROTATE','rotate')]:
        s+=panel(xx,1273,77,64,'navy',6,trim='#9c9b8c',detail=False)+icon(shape,xx+12,1280,52)
        s+=text(xx+38,1353,label,17,CREAM,'middle',700,2)
    s+=text(421,1395,'Conjure Spark created a free Spark',20,'#fff8e2','middle',500,2)
    s+=deck(29,1423,'DRAW','8')+deck(738,1423,'DISCARD','5',True)
    for args in [(146,'Spark',2,'spark','RUNE','Add 6 damage.'),(333,'Shield',1,'shield','RUNE','Add 5 shield.'),(520,'Focus',1,'book','TECHNIQUE','Draw 2 cards.')]:
        xx,name,cost,kind,role,desc=args;s+=card(xx,1406,174,170,name,cost,kind,role,desc)
    s+=panel(46,1586,748,76,'navy',8)
    s+=icon('spark',79,1596,43)+text(133,1621,'12',26,CREAM,weight=600)+text(173,1620,'DAMAGE',17,CREAM,weight=700)
    s+=icon('shield',358,1599,31)+text(397,1620,'0',26,CREAM,weight=600)+text(424,1620,'SHIELD',17,CREAM,weight=700)
    s+=icon('crystal',613,1597,28)+text(660,1620,'COST',18,CREAM,weight=700)+text(724,1621,'1',26,CREAM,weight=600)
    s+=path('M133 1627H578','none','#647282',1)+text(421,1650,'Incoming: 8',25,'#fc5053','middle',700,2)
    s+=panel(128,1666,584,87,'turquoise',11,shape='cast')
    s+=text(374,1728,'CAST',53,CREAM,'middle',700,4)+icon('crystal',479,1683,40)+text(544,1727,'1',45,CREAM,'middle',600,4)
    s+=text(421,1772,'Cast ends turn',21,'#fff6de','middle',500,2)
    s+=panel(47,1780,746,85,'navy',9)
    for i,(label,shape) in enumerate([('Menu','menu'),('Map','map'),('Guide','guide'),('Sound','sound')]):
        xx=49+i*185
        if i:s+=path(f'M{xx} 1790V1855','none','#667387',1.6)
        s+=icon(shape,xx+67,1789,49)+text(xx+92,1854,label,23,CREAM,'middle',700,2)
    (P/'pilot_review.svg').write_text(document(841,1870,s,'RC-011 r004 complete editable gameplay candidate'),encoding='utf-8')

def narrow():
    # Native 72-pixel cells and intentional clipped scroll viewport, not downscale.
    s=img('exports/crypt-background.png',0,0,360,800)+rect(0,0,360,47,'#101929')
    s+=text(12,31,'RUNE CAST',24,'#efb252',weight=700)+text(340,29,'II',25,CREAM,'end')
    s+=text(180,75,'Attack 8',18,'#ffd8a4','middle')+img('../r002/exports/shadeling.png',90,60,180,180)
    s+=text(180,224,'Shadeling · 32/32',18,CREAM,'middle',700)
    s+=panel(10,237,340,38,'navy',4)+icon('heart',22,246,23)+text(51,263,'24/30',17)+icon('crystal',139,245,20)+text(165,263,'3/3',17)+text(294,263,'Turn 2',17,CREAM,'middle')
    s+=panel(9,280,342,337,'navy',6)+text(180,307,'CIRCUIT COMPLETE',19,'#72f5b3','middle',700)
    # Interactive study of actual72px cells, all numbers/upright labels remain live.
    for row in range(4):
        for col in range(4):
            x=25+col*77;y=314+row*74
            kind={(0,0):'begin',(0,1):'spark',(0,2):'split',(2,2):'join',(3,2):'end'}.get((row,col),'empty')
            s+=img('ui/tile-'+('amber' if kind=='spark' else 'turquoise' if kind!='empty' else 'navy')+'.png',x,y,72,72)
            if kind=='spark':
                s+=icon('spark',x+18,y+18,36)+text(x+16,y+65,'6',17,CREAM,'middle')+text(x+9,y+15,'Spark',11,CREAM,weight=700)+energy_badge(x+60,y+13,0,20)
                s+=poly([(x+34,y+54),(x+66,y+54),(x+66,y+66),(x+34,y+66),(x+30,y+60)],'#d1a24d','#422c18',1)+text(x+49,y+64,'TEMP',8,'#17120b','middle',700,0)
            elif kind in ['begin','end']:
                s+=circle(x+36,y+34,18,'#07535a',TEAL,3)+poly([(x+36,y+24),(x+45,y+34),(x+36,y+44),(x+27,y+34)],TEAL)+text(x+36,y+65,kind.upper()+' 12' if kind=='end' else kind.upper(),11,CREAM,'middle',700)
            elif kind in ['split','join']:s+=icon(kind,x+22,y+20,33,TEAL)+text(x+36,y+14,kind.upper(),10,CREAM,'middle')
    # Exact72px geometry. Routes stop at icon faces; labels/costs stay upright.
    s+=beam('M79 348H119',width=4)+beam('M156 348H193',width=4)+beam('M237 348H280Q292 348 292 360V484Q292 494 281 494H237',width=4)+beam('M215 371V466',width=4)+beam('M215 519V552',width=4)
    for xx in [215,292]:s+=circle(xx,423,10,'#4d3215')+text(xx,429,'6',16,CREAM,'middle')
    # Stop at a visible scroll boundary. The controls are on a companion viewport.
    s+=rect(0,619,360,21,'#101929')+text(180,634,'Scroll down: wiring · cards · forecast · Cast',12,'#ddbd7e','middle')+rect(353,289,4,320,'#25334b',rx=2)+rect(353,299,4,112,'#d4b780',rx=2)
    (P/'pilot_narrow.svg').write_text(document(360,640,s,'RC-011 r004 native72px cells; vertical scroll review'),encoding='utf-8')
    s=img('exports/crypt-background.png',0,-460,360,1100)+rect(0,0,360,640,'#0c1624','none')
    s+=text(180,25,'Gameplay controls · scrolled view',17,CREAM,'middle')
    for i,(name,shape,count) in enumerate([('Straight','straight','4/4'),('Corner','corner','2/2'),('Split','split','0/1'),('Join','join','1/1')]):
        x=7+i*88;s+=panel(x,41,82,78,'navy',4)+text(x+41,58,name,12,CREAM,'middle')+icon(shape,x+24,60,35,TEAL if i==2 else AMBER)+text(x+41,110,count,16,CREAM,'middle')
    for x,label,shape in [(72,'Remove','remove'),(196,'Rotate','rotate')]:s+=panel(x,129,94,58,'navy',4)+icon(shape,x+6,139,34)+text(x+62,161,label,13,CREAM,'middle')
    s+=text(180,211,'Conjure Spark created a free Spark',13,CREAM,'middle')
    s+=card(97,225,166,168,'Spark',2,'spark','RUNE','Add 6 damage.')
    s+=group(deck(0,0,'DRAW','8'),transform='translate(5 256) scale(.80)')
    s+=group(deck(0,0,'DISCARD','5',True),transform='translate(285 256) scale(.80)')
    s+=text(180,414,'Hand scroll: Shield · Focus',13,'#d4bd92','middle')
    s+=panel(10,430,340,68,'navy',5)+icon('spark',18,440,31)+text(56,459,'12 damage',15)+icon('shield',170,442,24)+text(200,459,'0 shield',15)+text(180,487,'Cost 1 · Incoming 8',18,'#ffd09d','middle')
    s+=panel(21,500,318,64,'turquoise',7,shape='cast')+text(154,543,'CAST',32,CREAM,'middle',700,3)+icon('crystal',220,513,27)+text(263,541,'1',29,CREAM,'middle')
    s+=text(180,584,'Cast ends turn',16,CREAM,'middle')
    for i,(name,ico) in enumerate([('Menu','menu'),('Map','map'),('Guide','guide'),('Sound','sound')]):
        x=8+i*89;s+=panel(x,590,84,50,'navy',3)+icon(ico,x+7,605,22)+text(x+53,621,name,12,CREAM,'middle')
    (P/'pilot_narrow_controls.svg').write_text(document(360,640,s,'RC-011 r004 native scrolling controls companion'),encoding='utf-8')

def state_sheet():
    s=rect(0,0,1200,1450,'#101b2b')+text(30,44,'R004 · shared interaction and undirected geometry study',26,CREAM,weight=700)
    states=['normal','pressed','focused','selected','disabled','invalid','unavailable','focused+selected','focused+unavailable']
    oldspec=importlib.util.spec_from_file_location('oldstates',P.parents[1]/'button/build_materials.py');old=importlib.util.module_from_spec(oldspec);oldspec.loader.exec_module(old)
    for i,st in enumerate(states):
        y=82+i*75;s+=text(28,y+36,st,17)
        for j,mat in enumerate(['turquoise','navy']):
            xx=245+j*459;s+=panel(xx,y,426,59,mat,6,shape='cast' if j==0 else 'box')
            for tok in st.split('+'):
                if tok!='normal':
                    # Keep editable vector states independent from the base art.
                    ov=old.responsive_overlay_svg((426,59),tok);root=ET.fromstring(ov)
                    content=''.join(ET.tostring(e,encoding='unicode') for e in list(root) if not e.tag.endswith('title'))
                    s+=group(content,transform=f'translate({xx} {y})')
            s+=text(xx+213,y+39,'CAST · 1' if j==0 else 'Straight · 0 / 6' if 'unavailable' in st else 'Rotate',24,CREAM,'middle',600,3)
    s+=text(29,807,'Rotated undirected Spark · exact edge ports · upright labels',23,CREAM,weight=700)
    for i,deg in enumerate([0,90,180,270]):
        x=35+i*178;y=832;n=137;s+=panel(x,y,n,n,'amber',5)
        geom=beam('M0 64H128',AMBER,5)
        s+=group(geom,transform=f'translate({x} {y}) scale({n/128}) rotate({deg} 64 64)')+icon('spark',x+35,y+35,67)
        s+=text(x+10,y+24,'Spark',16,CREAM,weight=700)+text(x+13,y+122,'6',23)+energy_badge(x+n-20,y+20,2,30)+text(x+n/2,y+162,f'{deg}°',18,CREAM,'middle')
    s+=text(801,839,'Glyph sizes',20,CREAM,weight=700)
    for i,n in enumerate([24,32,48]):s+=icon('spark',801+i*95,858,n)+text(801+i*95,940,f'{n} px',17)
    s+=text(29,1041,'Endpoints-only / rotated endpoints · finite stock / placement states',22,CREAM,weight=700)
    for i,kind in enumerate(['begin','empty','empty','end']):
        x=35+i*137;y=1063;s+=tile(x,y,127,127,kind)
        if kind in ['begin','end']:
            s+=beam(f'M{x+63} {y}V{y+25}',TEAL,5)+text(x+63,y+118,kind.upper(),15,CREAM,'middle')
    s+=panel(642,1073,244,73,'navy',6)+icon('straight',659,1092,49,AMBER)+text(785,1104,'Straight',19,CREAM,'middle')+text(785,1134,'0 / 6',22,CREAM,'middle')
    s+=text(641,1175,'Stock exhausted · no piece available.',17)
    for x,mark,color,label in [(959,'+',TEAL,'eligible'),(1063,'×','#f0aa84','protected')]:
        s+=panel(x,1073,85,85,'navy',5)+text(x+43,1128,mark,39,color,'middle',700)+text(x+43,1181,label,15,CREAM,'middle')
    s+=text(29,1264,'Free Spark shares frame + glyph; TEMP is a separate live badge. No arrows encode circuit flow.',18)
    s+=tile(39,1287,137,137,'spark','SPARK',6,0,True)+text(201,1330,'Free Spark · 6 damage · cost 0',21)+text(201,1369,'Focus dashed ring; selected check; invalid cross; unavailable explanation.',17)
    s+=text(201,1410,'Synthetic review only. Godot theme/input/undirected evaluator remain separate implementation work.',16,'#ccb88c')
    (P/'pilot_states.svg').write_text(document(1200,1450,s,'RC-011 r004 state/geometry evidence'),encoding='utf-8')

def type_sheet():
    s=rect(0,0,1100,890,'#101b2b')+text(30,51,'R004 / live typography and compact values',29,CREAM,weight=700)
    samples=[('Display / 46 bold','Rune Cast',46),('Large action / 44 bold','CAST',44),('Card title / 24 semibold','Spark   Free Spark   Shield   Focus',24),('Body / 20 semibold','Add 6 damage.  Add 5 shield.  Draw 2 cards.',20),('Interaction / 18 semibold','Remove   Rotate   Draw   Discard',18),('Status / 20 semibold','Conjure Spark created a free Spark',20),('Values / 24 semibold','0 / 6    32 / 32    6  0  8  1',24),('Small labels / 15 semibold','RUNE   TECHNIQUE   TEMP   Incoming: 8',15)]
    for i,(role,value,n) in enumerate(samples):
        y=116+i*79;s+=text(31,y,role,15,'#c3ad82',stroke=0)+text(31,y+43,value,n,CREAM,weight=700 if n>30 else 600)
    s+=text(30,789,'Noto Serif variable: acquired r002; OFL file retained beside font. Font remains live in source SVG.',17)
    s+=text(30,821,'Pillow renders exact font for PNG review; current engine fallback and device import remain unverified.',17)
    s+=text(30,853,'No live action labels, costs, stock or card descriptions are baked into component art.',17)
    (P/'pilot_type.svg').write_text(document(1100,890,s,'RC-011 r004 typography specimen'),encoding='utf-8')

def tile_state_sheet():
    s=rect(0,0,1000,700,'#101b2b')+text(28,43,'R004 · Spark interaction states at actual cell sizes',26,CREAM,weight=700)
    entries=['unpowered','powered','selected','focused','invalid','unavailable','focused+selected']
    for idx,state in enumerate(entries):
        col=idx%4;row=idx//4;x=29+col*244;y=88+row*284
        s+=text(x,y,state,17,CREAM,weight=700)
        for n,dx,dy in [(137,0,15),(72,148,70)]:
            xx=x+dx;yy=y+dy
            s+=img('ui/tile-amber.png',xx,yy,n,n)
            powered=state!='unpowered';colr=AMBER if powered else '#90958f'
            s+=path(f'M{xx} {yy+n/2}H{xx+n}','none',colr,5 if n>100 else 3)
            if powered:
                # Non-directional collars distinguish power even in grayscale.
                rr=4 if n>100 else 2.5
                for px in [xx+10,xx+n-10]:s+=circle(px,yy+n/2,rr,'#63400e',AMBER,1.8 if n>100 else 1.3)
            gs=66 if n>100 else 36;s+=icon('spark',xx+(n-gs)/2,yy+(n-gs)/2,gs)
            s+=text(xx+9,yy+(20 if n>100 else 13),'Spark',16 if n>100 else 10,CREAM,weight=700)
            s+=text(xx+13,yy+n-12,'6',22 if n>100 else 15)+energy_badge(xx+n-16,yy+16,2,28 if n>100 else 21)
            if 'selected' in state:
                s+=rect(xx+5,yy+5,n-10,n-10,'none','#6df4d8',2)+path(f'M{xx+n-26} {yy+n-17}l5,5 10,-12','none','#fff1c3',3)
            if 'focused' in state:s+=f'<rect x="{xx+1}" y="{yy+1}" width="{n-2}" height="{n-2}" fill="none" stroke="#fff1c3" stroke-width="2" stroke-dasharray="7 4"/>'
            if state=='invalid':
                s+=rect(xx+4,yy+4,n-8,n-8,'none','#ed956b',2)+path(f'M{xx+n-27} {yy+n-27}l13,13m0,-13l-13,13','none','#ffdab0',3)
            if state=='unavailable':
                s+=rect(xx+6,yy+6,n-12,n-12,'#14253555')+circle(xx+n-18,yy+n-18,10,'#1b3041','#dfc389',2)+text(xx+n-18,yy+n-12,'i',14,CREAM,'middle',700)
            s+=text(xx+n/2,yy+n+24,f'{n}px',14,'#d8bd87','middle')
    s+=text(28,641,'Powered port collars add a non-directional shape cue; unpowered ports remain plain strokes.',15,'#d4c298')
    s+=text(28,676,'Separate vector overlays retain visible cost/value. Unavailable is a placement condition; no legacy Inspect control.',15,'#d4c298')
    (P/'pilot_tile_states.svg').write_text(document(1000,700,s,'RC-011 r004 tile state evidence at137and72'),encoding='utf-8')

def bake_text():
    ns='{http://www.w3.org/2000/svg}';ET.register_namespace('',ns[1:-1]);ET.register_namespace('xlink','http://www.w3.org/1999/xlink')
    dest=UI/'render';dest.mkdir(exist_ok=True)
    for src in P.glob('pilot*.svg'):
        root=ET.fromstring(src.read_text(encoding='utf-8'))
        for parent in root.iter():
            for el in list(parent):
                if el.tag!=ns+'text':continue
                a=el.attrib;value=''.join(el.itertext());size=round(float(a.get('font-size',20)))
                f=ImageFont.truetype(str(FONT),size);f.set_variation_by_axes([float(a.get('font-weight',600)),100])
                sw=max(0,round(float(a.get('stroke-width',2))/2));box=f.getbbox(value,anchor='ls',stroke_width=sw);advance=f.getlength(value)
                im=Image.new('RGBA',(max(1,box[2]-box[0]+4),max(1,box[3]-box[1]+4)))
                ImageDraw.Draw(im).text((2-box[0],2-box[1]),value,font=f,fill=a.get('fill',CREAM),anchor='ls',stroke_width=sw,stroke_fill='#080d15')
                buff=BytesIO();im.save(buff,format='PNG');x=float(a.get('x',0));y=float(a.get('y',0));anchor=a.get('text-anchor','start')
                x-=advance/2 if anchor=='middle' else advance if anchor=='end' else 0
                node=ET.Element(ns+'image',{'x':str(x+box[0]-2),'y':str(y+box[1]-2),'width':str(im.width),'height':str(im.height),'{http://www.w3.org/1999/xlink}href':'data:image/png;base64,'+base64.b64encode(buff.getvalue()).decode()})
                parent.insert(list(parent).index(el),node);parent.remove(el)
        (dest/src.name).write_text(ET.tostring(root,encoding='unicode'),encoding='utf-8')

def render():
    script=r'''const fs=require('fs'),path=require('path');
const sharp=require('C:/Users/nguye/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const P=path.resolve(__dirname,'..'),OUT=path.resolve(P,'../../../../output/art/rc-011/r004');
function inline(svg,base){return svg.replace(/xlink:href="([^"]+)"/g,(m,ref)=>{if(ref.startsWith('data:'))return m;const p=path.resolve(base,ref);let b=fs.readFileSync(p);if(p.endsWith('.svg'))b=Buffer.from(inline(b.toString(),path.dirname(p)));return 'xlink:href="data:'+(p.endsWith('.svg')?'image/svg+xml':'image/png')+';base64,'+b.toString('base64')+'"';});}
(async()=>{const list={'pilot_review.svg':'pilot-841x1870.png','pilot_narrow.svg':'pilot-360x640.png','pilot_narrow_controls.svg':'pilot-360x640-controls.png','pilot_states.svg':'pilot-states.png','pilot_type.svg':'pilot-type.png','pilot_tile_states.svg':'pilot-tile-states.png'};for(const [src,dst]of Object.entries(list)){await sharp(Buffer.from(inline(fs.readFileSync(path.join(__dirname,'render',src),'utf8'),P))).withIccProfile('srgb').png().toFile(path.join(OUT,dst));console.log(dst);}await sharp(path.join(OUT,'pilot-841x1870.png')).resize(720,1600).withIccProfile('srgb').png().toFile(path.join(OUT,'pilot-720x1600.png'));await sharp(path.join(OUT,'pilot-841x1870.png')).resize(450,1000).withIccProfile('srgb').png().toFile(path.join(OUT,'pilot-450x1000.png'));await sharp(path.join(OUT,'pilot-states.png')).greyscale().png().toFile(path.join(OUT,'pilot-states-monochrome.png'));})();'''
    js=UI/'render_review.cjs';js.write_text(script,encoding='utf-8');subprocess.run([NODE,str(js)],check=True)

def build():
    prepare_materials();main();narrow();state_sheet();type_sheet();tile_state_sheet();bake_text();render()
    for src,dst,size in [('tile-amber.png','spark_tile.png',(256,256)),('cast-button-base.png','button_primary.png',(512,128)),('navy-panel-base.png','button_secondary.png',(512,128))]:
        Image.open(UI/src).convert('RGBA').resize(size,Image.Resampling.LANCZOS).save(P/'exports'/dst,icc_profile=ICC)
    for name,face,rim,wh in [('spark_tile','painted-face-amber.png','painted-frame.png',(512,512)),('button_primary','cast-button-face.png','cast-button-rim.png',(1024,256)),('button_secondary','navy-panel-face.png','navy-panel-rim.png',(1024,256))]:
        s=group(img(face,0,0,*wh),'painted_material')+group(img(rim,0,0,*wh),'painted_gold_and_dark_rim')
        (UI/f'{name}.svg').write_text(document(*wh,s,'r004 separately editable painted material and rim'),encoding='utf-8')
    meta={'revision':'r004','status':'complete constructed candidate; owner acceptance not inferred','source_design_size':[841,1870],
          'preview_sizes':[[841,1870],[720,1600],[450,1000],[360,640]],
          'native_narrow':{'cell_size':72,'viewport':[360,640],'scroll_boundary':{'y':619,'content':'Wiring/cards/forecast/Cast in companion viewport'},'source_svg':'pilot_narrow.svg','companion_source_svg':'pilot_narrow_controls.svg'},
          'source_mapping':{'environment':'exports/crypt-background.png','character':'../r002/exports/shadeling.png','materials':'ui/materials/*.png','glyph':'ui/spark.svg','editable_composition':'pilot_review.svg'},
          'editing_actions':['Remove','Rotate'],'state_tokens':['normal','pressed','focused','selected','disabled','invalid','unavailable','focused+selected','focused+unavailable'],
          'sample_rotations':[0,90,180,270],'glyph_sizes':[24,32,48],'canonical_ports':{'N':[64,0],'E':[128,64],'S':[64,128],'W':[0,64]},
          'tile_state_tokens':['unpowered','powered','selected','focused','invalid','unavailable','focused+selected'],'tile_states_source':'pilot_tile_states.svg',
          'painted_sources':{'tile':'ui/painted_tile.ora','primary':'ui/cast-button.ora','secondary':'ui/navy-panel.ora'},
          'material_exports':{'tile':'exports/spark_tile.png','primary':'exports/button_primary.png','secondary':'exports/button_secondary.png'},
          'slice_caps_export_LTRB':{'tile':[24,24,24,24],'primary_cast':[56,18,56,18],'secondary':[38,20,38,20]},
          'slice_refinement':'Generated sculpted rims require larger fixed corner/end caps than r001. MainCast uses35logicalpx endplates at87pxheight; tile/board and navy caps remainfixed duringstretch. Pixel caps describe candidate exports; live hitboxes stay rectangular.',
          'circuit_semantics':'Undirected compatible port pairs. SVG circuit geometry has no arrowheads. Rotate action icon retains its action arrow.',
          'visual_example':'Main reproduces official visual-example layout/values including BOSS, infinity, floor3, Turn2, Draw8/Discard5; not a guaranteed hand, balance commitment, roster change or implemented rules claim. Finite0/6 inset in state sheet.',
          'font':'../r002/type-geometry/fonts/NotoSerif-Variable.ttf','paint_method':'New original r004 generated crypt, empty-tile, navy-panel and cast-button paintings; exact prompts retained under raw/. New UI paint genuinely separated into material/rim ORA layers and recolored variants, with editable SVG icons, labels and geometry. No approved screenshot pixels or underlay linked into gameplay source. r002 supplies acquired font and selected character/glyph geometry only.',
          'character_transform':{'canvas':512,'display_size':384,'top_left':[254,92],'foot_export':[256,448],'screen_foot':[446,428]},
          'remaining':'Owner review; full runtime import/theme, undirected model/controls and real device behavior not implemented by this source.'}
    (UI/'composition-metadata.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')
    print('r004 full composition built')

if __name__=='__main__':build()
